package Ashafix::Model;
#===============================================================================
#
#         FILE:  Model.pm
#
#  DESCRIPTION:  Data model for Ashafix
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/05/2011 05:45:32 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use DBIx::Simple;
use SQL::Abstract;
use Carp qw/ croak confess /;
use Mojo::Loader;

my $DB;

sub new {
    my $class = shift;
    my %config = @_;

    foreach(qw/ dsn user password tabledefs /) {
        croak "No `$_' was passed!" unless $config{$_};
    }

    my $self = bless {}, $class;

    unless($DB) {
        $DB = DBIx::Simple->connect(@config{qw/dsn user password/},
            {
                RaiseError => 1,
                #keep_statements => 64,
            }
        ) or die DBIx::Simple->error;
        $DB->abstract = SQL::Abstract->new(
            case => 'lower',
            logic => 'and',
            convert => 'upper'
        );

        my $modules = [
            grep { !/^Ashafix::Model::Base$/ } @{Mojo::Loader->search('Ashafix::Model')}
        ];
        foreach my $pm (@$modules) {
            my $e = Mojo::Loader->load($pm);
            croak "Loading `$pm' failed: $e" if ref $e;
            my ($basename) = $pm =~ /.*::(.*)/;
            $self->{modules}{lc $basename} = $pm->new($config{tabledefs});
        }
    }
    return $self;
}

sub model {
    my ($self, $model) = @_;
    return $self->{modules}{$model} || confess "Unknown model `$model'";
}

# Regular function, proxies $DB->query to simplify debugging
sub query {
    print STDERR "QUERY: $_[0] [@_[1 .. $#_]]\n";
    $DB->query(@_);
}

1;
