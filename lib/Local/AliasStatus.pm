package Local::AliasStatus;
#===============================================================================
#
#         FILE:  AliasStatus.pm
#
#  DESCRIPTION:  A class that captures the status (deliverability, POP/IMAP
#                mailbox etc. of an alias and renders it to output. Currently
#                only HTML output as colored bars in the account overview is
#                implemented but something like JSON would make sense.
#
#         BUGS:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  10/21/2011 05:34:30 PM
#     REVISION:  ---
#===============================================================================
use 5.010;
use strict;
use warnings;
use List::MoreUtils qw/any/;

my $STATUS_NORMAL = 0;
my $STATUS_HILITE = 1;

my ($sstxt, $rec_delim, %colors);

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
        destinations    => [
            map { split /,/ } $ctrl->model('alias')->get_goto_by_address($alias)->flat
        ],
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
    my $cdoms = $self->{controller}->cfg('show_custom_domains');
    my $ccols = $self->{controller}->cfg('show_custom_colors');
    my $s = '';

    foreach my $test ( [deliverable => 'undeliverable'], [popimap => 'popimap'] ) {
        given($self->{$test->[0]}) {
            when($STATUS_NORMAL) { $s .= "${sstxt}&nbsp;"; }
            when($STATUS_HILITE) { $s .= _html_colorstatus($colors{$test->[1]}); }
            default { die "BUG: invalid $test->[0] status `$self->{$test->[0]}'"; }
        }
    }

    if($self->{custom_domain}) {
        $s .= _html_colorstatus( $ccols->{firstidx { $_ eq $self->{custom_domain} } @$cdoms} );
    } else {
        $s .= "${sstxt}&nbsp;";
    }

    return $s;
}

# NOTE regular function!
sub _html_colorstatus {
    my $color = shift;
    return "<span style=\"background-color:$color\">$sstxt</span>&nbsp;";
}

1;
