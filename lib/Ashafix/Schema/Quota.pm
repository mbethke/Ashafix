package Ashafix::Schema::Quota;
#===============================================================================
#
#         FILE:  Quota.pm
#
#  DESCRIPTION:  Quota model, distinguishes between old and new quota tables
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  10/29/2011 03:22:20 PM
#     REVISION:  ---
#===============================================================================
use 5.010;
use strict;
use warnings;
use parent 'Ashafix::Schema::Base';

our %snippets = (
    delete_everything_old   => "DELETE FROM %table_quota",
    delete_everything_new   => "DELETE FROM %table_quota2",
);

our %queries = (
    find_by_user_old    => "SELECT * FROM %table_quota WHERE username=?",
    delete_old          => "DELETE FROM %table_quota WHERE username=?",
    find_by_user_new    => "SELECT * FROM %table_quota2 WHERE username=?",
    delete_new          => "DELETE FROM %table_quota2 WHERE username=?",
);

sub new {
    my ($class, $config) = @_;
    my $self = $class->SUPER::new($config);

    foreach(grep { /_old$/ } keys %queries) {
        no strict 'refs';
        my $nosuff  = substr($_, 0, -4); # cut off suffix
        my $aliasto = $nosuff . ($config->{newquota} ? '_new' : '_old' );
        *{"$nosuff"} = *{"$aliasto"};    # alias find_by_user => find_by_user_{old,new}
    }
    return $self;
}

sub delete_everything {
    Ashafix::Schema::query($snippets{delete_everything_old});
    Ashafix::Schema::query($snippets{delete_everything_new});
}
