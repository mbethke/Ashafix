package Ashafix::Model::Alias;
#===============================================================================
#
#         FILE: Alias.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/12/2012 08:30:08 AM
#     REVISION: ---
#===============================================================================

use Mojo::Base 'Ashafix::Model::Base'; 

# Return a list of destination addresses for a given alias
sub list_gotos {
    my ($self, $alias) = @_;
    return $self->schema('alias')->get_goto_by_address($alias)->flat;
}

# Return the subset of the 2 or 3 address arguments that exists as aliases
sub get_address {
    my $self = shift;
    my $s = $self->schema('alias');
    2 == @_ and return $s->get_address_2(@_)->flat;
    3 == @_ and return $s->get_address_3(@_)->flat;
    die "Ashafix::Model::Alias::get_address needs 2 or 3 arguments";
}

1;
