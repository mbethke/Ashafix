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
use feature qw/switch/;
use Mojo::Base 'Ashafix::Controller';
use List::Util qw/first/;
use List::MoreUtils qw/firstidx/;
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
    my ($target_domain, $is_globaladmin);
    my $page_size = $self->cfg('page_size');

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

    unless(first { $_ eq $domain } @allowed_domains) {
        # Domain parameter not in list of allowed domains
        $self->flash(error => $self->l('invalid_parameter'));
        return $self->redirect_to('domain-list');
    }

    $self->session(list_virtual_sticky_domain => $domain);

    if($self->cfg('alias_domain')) {
        # First try to get a list of other domains pointing to this currently
        # chosen one (AKA alias domains)
        @alias_domains = $self->model('aliasdomain')->select_by_target($domain, $display, $page_size)->hashes;

        # Now let's see if the current domain itself is an alias for another domain
        $target_domain = $self->model('aliasdomain')->select_by_alias($domain)->hash;
    }

    @aliases = $self->model('complex')->get_addresses_by_domain(
        search  => $search,
        domain  => $domain,
        offset  => $display,
        limit   => $page_size,
        domains => [ @allowed_domains ],
    );

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

    );

    # TODO simplify. The _show variables are superfluous
    my ($can_add_alias, $can_add_mailbox,
        $display_back, $display_back_show,
        $display_up_show,
        $display_next, $display_next_show);

    my $limit = get_domain_properties($domain);

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
    $can_add_alias   = (0 == $limit->{aliases} or $limit->{alias_count}   < $limit->{aliases});
    $can_add_mailbox = (0 == $limit->{mailbox} or $limit->{mailbox_count} < $limit->{mailboxes})
    if($limit['mailboxes'] == 0) {

    $limit ['aliases']    = eval_size ($limit ['aliases']);
    $limit ['mailboxes']    = eval_size ($limit ['mailboxes']);
    $limit ['maxquota']    = eval_size ($limit ['maxquota']);
}

$gen_show_status = array ();
$check_alias_owner = array ();

if ((is_array ($tAlias) and sizeof ($tAlias) > 0))
    for ($i = 0; $i < sizeof ($tAlias); $i++) {
        $gen_show_status [$i] = gen_show_status($tAlias[$i]['address']);
        $check_alias_owner [$i] = check_alias_owner($SESSID_USERNAME, $tAlias[$i]['address']);
    }

$gen_show_status_mailbox = array ();
$divide_quota = array ('current' => array(), 'quota' => array());
if ((is_array ($tMailbox) and sizeof ($tMailbox) > 0))
    for ($i = 0; $i < sizeof ($tMailbox); $i++) {
        $gen_show_status_mailbox [$i] = gen_show_status($tMailbox[$i]['username']);
        if(isset($tMailbox[$i]['current'])) {
            $divide_quota ['current'][$i] = divide_quota ($tMailbox[$i]['current']);
        }
        if(isset($tMailbox[$i]['quota'])) {
            $divide_quota ['quota'][$i] = divide_quota ($tMailbox[$i]['quota']);
        }
        if(isset($tMailbox[$i]['quota']) && isset($tMailbox[$i]['current']))
        {
          $divide_quota ['percent'][$i] = min(100, round(($divide_quota ['current'][$i]/max(1,$divide_quota ['quota'][$i]))*100));
          $divide_quota ['quota_width'][$i] = ($divide_quota ['percent'][$i] / 100 * 120);
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

# TODO use this
package AliasStatus;
use strict;
use warnings;

my $STATUS_NORMAL = 0;
my $STATUS_HILITE = 1;

my ($sstxt, $rec_delim, %colors);

# Status object for aliases, currently only used to render colored bars in the
# account overview
sub new
{
    my ($class, $ctrl, $alias) = @_;

    unless($sstxt) {
        # Initialize package globals
        $sstxt = $ctrl->cfg('show_status_text');
        $colors{$_} = $ctrl->cfg("show_${_}_color") foreach(qw/ undeliverable popimap /);
        $rec_delim = $ctrl->cfg('recipient_delimiter');
    }

    my $self = bless {
        alias           => $alias,
        destinations    => [ split /,/, $ctrl->model('alias')->get_goto_by_address($alias)->flat ],
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
            # Address is not a known mailbox, check for vacation domain
            my $domain = lc substr $catchall, 1;
            my $vacdomain = lc $domain =~ /\@(.*)/;
            if($vacdomain eq lc $self->{controller}->cfg('vacation_domain')) {
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
    $self->{popimap} = (first { $_ eq $self->{alias} } map { $stripdelim->($_) } @{$self->{dest}}) ?
    $STATUS_HILITE : $STATUS_NORMAL;
}

sub _check_custom_dest {
    my $self = shift;
    my $dest = $self->{dest};
    my $cdoms = $self->{controller}->cfg('show_custom_domains');

    CDOMAIN:
    foreach my $cdom_ind ( 0 .. $#{$cdoms} ) {
        if(first { /$cdoms->[$cdom_ind]$/ } @{$self->{dest}}) {
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
