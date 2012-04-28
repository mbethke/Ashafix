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
use Carp qw/ croak /;
use Mojo::Loader;
use Try::Tiny;

my $DB;
my @connectargs;

sub new {
    my $class = shift;
    my %config = @_;

    foreach(qw/ dsn user password tabledefs newquota /) {
        croak "No `$_' was passed!" unless defined $config{$_};
    }

    my $self = bless {}, $class;

    unless($DB) {
        @connectargs = @config{qw/dsn user password/};
        $DB = _connect(@connectargs);
        
        my $modules = [
            grep { !/^Ashafix::Model::Base$/ } @{Mojo::Loader->search('Ashafix::Model')}
        ];
        foreach my $pm (@$modules) {
            my $e = Mojo::Loader->load($pm);
            croak "Loading `$pm' failed: $e" if ref $e;
            my ($basename) = $pm =~ /.*::(.*)/;
            $self->{modules}{lc $basename} = $pm->new(\%config);
        }
        $self->{modules}{''} = $self;
    }
    return $self;
}

sub model {
    my ($self, $model) = @_;
    return $self->{modules}{$model // ''} || croak "Unknown model `$model'";
}

# Regular function, proxies $DB->query to simplify debugging
sub query {
    my @query = @_;
    print STDERR "QUERY: $query[0] ", ($#query >=1 ? "[@query[1 .. $#query]]" : ''), "\n";
    try {
        $DB->query(@query);
    } catch {
        # Reconnect and retry upon loss of connection
        # TODO is this exception message the same for Postgres?
        /server has gone away/ and $DB = _connect(@connectargs);
        $DB->query(@query);
    };
}

# Transaction support
sub begin    { $DB->begin } 
sub commit   { $DB->commit }
sub rollback { $DB->rollback }

# Set up module-global connection handle. Not a method!
sub _connect {
    my $db = DBIx::Simple->connect(@_,
        {
            RaiseError => 1,
            #keep_statements => 64,
        }
    ) or die DBIx::Simple->error;
    $db->abstract = SQL::Abstract->new(
        case => 'lower',
        logic => 'and',
        convert => 'upper'
    );
    return $db;
}

1;
