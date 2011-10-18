package Ashafix::Controller::Virtual;
#===============================================================================
#
#         FILE:  Virtual.pm
#
#  DESCRIPTION:  Virtual domains
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/11/2011 12:49:11 AM
#     REVISION:  ---
#===============================================================================
use 5.010;
use feature qw/switch/;
use Mojo::Base 'Ashafix::Controller';
use List::Util qw/min max/;
use List::MoreUtils qw/any none/;
use Data::Dumper;

sub create {
    my $self = shift;
    die "unimplemented";
}

sub delete {
    my $self = shift;
    my $domain = $self->param('domain');
    die "unimplemented";
}

sub list {
    my $self = shift;
    my $user = $self->auth_get_username;
    my (@allowed_domains, @aliases, @alias_domains, @mailboxes);
    my (@gen_show_status, @is_alias_owner, @gen_show_status_mailbox);
    my %divide_quota;
    my ($target_domain, $is_globaladmin, $can_create_alias_domain);
    state $page_size = $self->cfg('page_size');

    # Get all domains for this admin
    if($self->auth_has_role('globaladmin')) {
        $is_globaladmin = 1;
        @allowed_domains = $self->model('domain')->get_real_domains->flat;
    } else {
        $is_globaladmin = 0;
        $self->model('domain')->get_domains_for_admin($user)->flat;
    }

    unless(@allowed_domains) {
        $self->flash(error => $self->l(
                $is_globaladmin ? 'no_domains_exist' : 'no_domains_for_this_admin')
        );
        return $self->redirect_to('domain-list');
    }

    my $domain  = lc( $self->param('domain') // $allowed_domains[0]);
    my $display = int($self->param('limit')  // 0);
    my $search  =     $self->param('search');

    unless(any { $_ eq $domain } @allowed_domains) {
        # Domain parameter not in list of allowed domains
        $self->flash(error => $self->l('invalid_parameter'));
        return $self->redirect_to('domain-list');
    }

    $self->session(list_virtual_sticky_domain => $domain);

    if($self->cfg('alias_domain')) {
        @alias_domains = $self->model('aliasdomain')->select_by_domain($domain, $page_size, $display)->hashes;
        $can_create_alias_domain = none { $_->{target_domain} eq $domain } @alias_domains;
        # TODO: set $can_create_alias_domain = 0; if all domains (of this admin) are already used as alias domains
    }

    @aliases = $self->model('complex')->get_addresses_by_domain(
        search  => $search,
        domain  => $domain,
        offset  => $display,
        limit   => $page_size,
        domains => [ @allowed_domains ],
    )->hashes;

    my $display_mailbox_aliases = $self->cfg('alias_control_admin');
    @mailboxes = $self->model('complex')->get_mailboxes(
            search  => $search,
            domain  => $domain,
            offset  => $display,
            limit   => $page_size,
            cfg     => {
                map { ($_ => $self->cfg($_)) }
                qw/ display_mailbox_aliases display_mailbox_aliases
                vacation_control_admin used_quotas new_quota_table /
            },

    )->hashes;
    if($display_mailbox_aliases) {
        foreach my $mbox (@mailboxes) {
            $mbox->{goto_mailbox} = 0;
            foreach my $goto (split /,/, $mbox->{goto}) {
                state $vacation = $self->cfg('vacation');
                state $vacation_domain = $self->cfg('vacation_domain');
                state $rec_delim = $self->cfg('recipient_delimiter');

                my $goto_noext = $goto;
                $rec_delim and $goto_noext =~ s/$rec_delim[^$rec_delim\@]*@/\@/o;
                if(any { $_ eq $mbox->{username} } $goto, $goto_noext) {
                    # delivers to mailbox
                    $mbox->{goto_mailbox} = 1;
                } elsif($vacation and index $goto_noext, "\@$vacation_domain") {
                    # vacation alias - TODO check for full vacation alias
                    # skip the vacation alias, vacation status is detected otherwise
                } else {
                    # forwarding to other alias
                    push @{$mbox->{goto_other}}, $goto; 
                }
            }
        }
    }

    # TODO simplify. The _show variables are superfluous
    my ($can_add_alias, $can_add_mailbox,
        $display_back, $display_back_show,
        $display_up_show,
        $display_next, $display_next_show);

    my $limit = $self->get_domain_properties($domain);

    if($display >= $page_size) {
        $display_back_show = 1;
        $display_back = $display - $page_size;
    }
    $display_up_show = ($limit->{alias_count} > $page_size or $limit->{mailbox_count} > $page_size);
    if(
        (($display + $page_size) < $limit->{alias_count}) or
        (($display + $page_size) < $limit->{mailbox_count}))
    {
        $display_next_show = 1;
        $display_next = $display + $page_size;
    }
    $can_add_alias   = (0 == $limit->{aliases}   or $limit->{alias_count}   < $limit->{aliases});
    $can_add_mailbox = (0 == $limit->{mailboxes} or $limit->{mailbox_count} < $limit->{mailboxes});

    if(0 == $limit->{mailboxes}) {
        $limit->{$_} = $self->eval_size($limit->{$_}) foreach(qw/ aliases mailboxes maxquota /);
    }

    foreach my $alias (@aliases) {
        print "ALIAS: ", Dumper($alias);
        push @gen_show_status, AliasStatus->new($self, $alias->{address});
        push @is_alias_owner, $self->check_alias_owner($self->auth_get_username, $alias->{address});
    }

    foreach my $i (0 .. $#mailboxes) {
        my $mbox = $mailboxes[$i];
        $gen_show_status_mailbox[$i] = AliasStatus->new($self, $mbox->{username});
        $divide_quota{$_}[$i] = $self->divide_quota($mbox->{$_}) foreach(qw/ current quota /);
        if(defined $mbox->{current} and defined $mbox->{current}) {
            $divide_quota{percent}[$i] = min(100, sprintf("%d", ($divide_quota{current}[$i] / max(1, $divide_quota{quota}[$i])) * 100));
            $divide_quota{quota_width}[$i] = ($divide_quota{percent}[$i] * 1.2); # TODO redundant?
        }
    }
    
    $self->render(
        domain           => $domain,
        current_limit    => $page_size,
        domains          => \@allowed_domains,
        mailbox          => \@mailboxes,         # TODO should be called "mailboxes"
#hash     limit (keys: aliases, mailboxes, maxquota, alias_count, alias_pgindex_count, mailbox_count, mbox_pgindex_count)
   #bool     can_add_alias
   #bool     can_add_mailbox
   #?        display_back_show
   #?        display_back
   #int      highlight_at
    );
}

sub eval_size {
    my ($self, $size) = @_;

    return $self->l('pOverview_unlimited') if $size == 0;
    return $self->l('pOverview_disabled')  if $size < 0;
    return $size;
}

sub check_alias_owner { 
    my ($self, $username, $alias) = @_;

    return 1 if $self->auth_has_role('globaladmin');

    my ($localpart) = split /\@/, $alias;
    return if(!$self->cfg('special_alias_control') and exists $self->cfg('default_aliases')->{$localpart});
    return 1;
}

sub divide_quota {
    my ($self, $quota) = @_;
    state $mult = $self->cfg('quota_multiplier');

    return unless defined $quota;
    return $quota if -1 == $quota;
    return sprintf("%.2d", ($quota / $mult) + 0.05);
}





package AliasStatus;
use strict;
use warnings;
use List::MoreUtils qw/any/;

my $STATUS_NORMAL = 0;
my $STATUS_HILITE = 1;

my ($sstxt, $rec_delim, %colors);

# Status object for aliases, currently only used to render colored bars in the
# account overview
sub new
{
    my ($class, $ctrl, $alias) = @_;

    print $class,"->new(`$ctrl', `$alias')\n";

    unless($sstxt) {
        # Initialize package globals
        $sstxt = $ctrl->cfg('show_status_text');
        $colors{$_} = $ctrl->cfg("show_${_}_color") foreach(qw/ undeliverable popimap /);
        $rec_delim = $ctrl->cfg('recipient_delimiter');
    }

    my $self = bless {
        alias           => $alias,
        destinations    => [ map { split /,/ } $ctrl->model('alias')->get_goto_by_address($alias)->flat ],
        deliverable     => $STATUS_NORMAL,
        popimap         => $STATUS_NORMAL,
        custom_domain   => '',
        controller      => $ctrl,
    }, $class;

    $ctrl->cfg('show_undeliverable') and $self->_check_deliverable;
    $ctrl->cfg('show_popimap') and $self->_check_popimap;
    @{$ctrl->cfg('show_custom_domains')} and $self->_check_custom_dest;

    return $self;
}

sub _check_deliverable {
    my $self = shift;

    # Check for undeliverable alias destination
    DELIVERABLE:
    foreach my $goto (@{$self->{destinations}}) {
        say "DELIVERABLE: $goto\n";
        my ($catchall) = $goto =~ /(\@.*)/;
        my $addr;

        # This will misbehave if the delimiter is "0". Your fault for choosing such
        # an inane delimiter, use "+" or something.
        if($rec_delim) {
            my $sans_delim;
            ($sans_delim = $goto) =~ s/\Q$rec_delim\E[^\Q$rec_delim\E]*\@/@/;
            $addr = $self->{controller}->model('alias')->get_address_3($goto, $catchall, $sans_delim)->flat;
        } else {
            $addr = $self->{controller}->model('alias')->get_address_2($goto, $catchall)->flat;
        }

        unless($addr) {
            state $vacation_domain = lc $self->{controller}->cfg('vacation_domain');
            # Address is not a known mailbox, check for vacation domain
            my $domain = lc substr $catchall, 1;
            my $vacdomain = lc $domain =~ /\@(.*)/;
            if($vacdomain eq $vacation_domain) {
                $self->deliverable = $STATUS_NORMAL;
                last DELIVERABLE;
            }
            # Check for configured exceptions
            foreach(@{$self->cfg('show_undeliverable_exceptions')}) {
                if($domain eq lc $_) {
                    $self->deliverable = $STATUS_NORMAL;
                    last DELIVERABLE;
                }
            }
            $self->{deliverable} = $STATUS_HILITE;
            last DELIVERABLE;
        }
    }
}

sub _check_popimap {
    my $self = shift;
    my $sans_delim = '';

    my $stripdelim = $rec_delim ?
    sub {
        my $s = shift;
        $s =~ s/\Q$rec_delim\E[^\Q$rec_delim\E]*\@/@/;
        ($s, $_[0])
    } :
    sub { $_[0] };

    # If the address passed in appears in its own goto field, its POP/IMAP
    $self->{popimap} = (any { $_ eq $self->{alias} } map { $stripdelim->($_) } @{$self->{dest}}) ?
    $STATUS_HILITE : $STATUS_NORMAL;
}

sub _check_custom_dest {
    my $self = shift;
    my $dest = $self->{dest};
    my $cdoms = $self->{controller}->cfg('show_custom_domains');

    CDOMAIN:
    foreach my $cdom_ind ( 0 .. $#{$cdoms} ) {
        if(any { /$cdoms->[$cdom_ind]$/ } @{$self->{dest}}) {
            $self->{custom_domain} = $cdoms->[$cdom_ind];
            last CDOMAIN;
        }
    }
}

# Render to HTML
sub html {
    my $self = shift;
    my $txt = $self->{txt};
    my $cdoms = $self->{controller}->cfg('show_custom_domains');
    my $ccols = $self->{controller}->cfg('show_custom_colors');
    my $s = '';

    foreach my $test ( [deliverable => 'undeliverable'], [popimap => 'popimap'] ) {
        given($self->{$test->[0]}) {
            when($STATUS_NORMAL) { $s .= "${txt}&nbsp;"; }
            when($STATUS_HILITE) { $s .= _html_colorstatus($colors{$test->[1]}); }
            default { die "BUG: invalid $test->[0] status `$self->{$test->[0]}'"; }
        }
    }

    if($self->{custom_domain}) {
        $s .= _html_colorstatus( $ccols->{firstidx { $_ eq $self->{custom_domain} } @$cdoms} );
    } else {
        $s .= "${txt}&nbsp;";
    }

    return $s;
}

# NOTE regular function!
sub _html_colorstatus {
    my $color = shift;
    return "<span style=\"background-color:$color\">$sstxt</span>&nbsp;";
}


# TODO use this
package AliasGotoAddress;
use strict;
use warnings;

sub new {
    my ($class, $gotostring, $limit, $more_tpl) = @_;
    my $self = bless {
        addrs => [ split /,/, $gotostring ],
    };
    if($limit) {
        $self->{limit} = $limit;
        $self->{more}  = sprintf($more_tpl, @{$self->{addrs}} - $limit);
    }
    return $self;
}

# Render to HTML
sub html {
    my $self =  shift; 
    return join('<br>', @{$self->{addrs}}[0 .. $self->{limit} - 1]) . $self->{more};
}

1;
