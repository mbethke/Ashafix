package Ashafix::Schema;
#===============================================================================
#
#         FILE:  Schema.pm
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
        $self->_setup_dbms_specifics($DB, $config{dsn});

        my $modules = [
            grep { $_ ne 'Ashafix::Schema::Base' } @{Mojo::Loader->search('Ashafix::Schema')}
        ];
        foreach my $pm (@$modules) {
            my $e = Mojo::Loader->load($pm);
            croak "Loading `$pm' failed: $e" if ref $e;
            my ($basename) = $pm =~ /.*::(.*)/;
            $self->{modules}{lc $basename} = $pm->new(\%config);
        }
        $self->{modules}{''} = $self;   # Empty model name gives access to Model object
    }
    return $self;
}

# Get a schema object by name
sub schema {
    my ($self, $schema) = @_;
    return $self->{modules}{$schema // ''} || croak "Unknown schema `$schema'";
}

# Return the DBI error string for the last query
sub error { $DB->error }

# Return a list of avaialable schema names
# Probably only for test code
sub schemas { return grep { $_ ne '' } keys %{$_[0]->{modules}} }

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
#    $db->abstract = SQL::Abstract->new(
#        case => 'lower',
#        logic => 'and',
#        convert => 'upper'
#    );
    return $db;
}

sub _setup_dbms_specifics {
    my ($self, $db, $dsn) = @_;
    my $dbh = $db->dbh;
    my ($driver) = $dsn =~ /DBI:([^:]+):/i;
    if('Pg' eq $driver) {
        # PostgreSQL has a weird boolean type default
        $dbh->{pg_bool_tf} = 0;     # use 0/1 instead of 'f'/'t'
        return;
    }
}

1;
