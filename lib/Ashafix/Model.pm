package Ashafix::Model;
#===============================================================================
#
#         FILE:  Model.pm
#
#  DESCRIPTION:  High-level data model for Ashafix
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
use Carp qw/ croak /;
use Mojo::Loader;
use Try::Tiny;
use Ashafix::Schema;
use Mojo::Base -base;

has modules => sub { {} };
has 'root_schema';

sub new {
    my $class = shift;
    my %args = @_;
    my $self = $class->SUPER::new(@_);

    foreach my $pm (grep { $_ ne 'Ashafix::Model::Base' } @{Mojo::Loader->search('Ashafix::Model')}) {
        my $e = Mojo::Loader->load($pm);
        croak "Loading `$pm' failed: $e" if ref $e;
        my ($basename) = $pm =~ /.*::(.*)/;
        $self->modules->{lc $basename} = $pm->new(%args);
    }
    return $self;
}

# Get a model object by name
sub model {
    my ($self, $model) = @_;
    return $self->{modules}{$model} || croak "Unknown model `$model'";
}

# Get a schema object by name
sub schema {
    my ($self, $schema) = @_;
    return $self->root_schema->schema($schema) || croak "Unknown schema `$schema'";
}

# Return why the last schema call failed
sub schema_err { shift->root_schema->error }

# Return a list of avaialable model names
# Probably only for test code
sub models { return grep { $_ ne '' } keys %{$_[0]->{modules}} }

1;
