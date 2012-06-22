package Ashafix::Model::Domain;
#===============================================================================
#
#         FILE: Domain.pm
#
#  DESCRIPTION: Domain class
#
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/12/2012 08:30:08 AM
#===============================================================================

use Mojo::Base 'Ashafix::Model::Base'; 
 
# Return a hash of hashes keyed by domain name as passed in; values are domain statistics
# TODO does this make sense or should it return some kind of stats objects?
sub stats {
    my $self = shift;
    my $s = $self->schema('complex');
        
    my %domain_props = map { ( $_->{domain} => $_ ) } $s->get_domain_stats(@_)->hashes;
    $domain_props{$_->{domain}}{alias_count} = $_->{alias_count}
        for $s->get_aliases_per_domain(@_)->hashes;
    return \%domain_props;
}

sub aliases {
    my $self = shift;
    $self->schema('complex')->get_domain_stats(@_); 
}

1;
