package Ashafix::Model::Aliasdomain;
#===============================================================================
#
#         FILE: Aliasdomain.pm
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
use Ashafix::Result::Aliasdomain;

sub list_paged {
    my ($self, $domain, $page_size, $offset) = @_;
    # TODO convert created/modified fields to DateTime?
    return map { Ashafix::Result::Aliasdomain->new( %$_ ) }
        $self->schema('aliasdomain')->select_by_domain($domain, $domain, $page_size, $offset)->hashes;
}

1;
