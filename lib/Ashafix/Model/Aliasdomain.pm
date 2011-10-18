package Ashafix::Model::Aliasdomain;
#===============================================================================
#
#         FILE:  Aliasdomain.pm
#
#  DESCRIPTION:  Domain alias table
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/21/2011 12:49:08 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use base 'Ashafix::Model::Base';

our %queries = (
    delete_by_alias     => "DELETE FROM %table_alias_domain WHERE alias_domain=?",
);

our %snippets = (
    select_by_domain     => "SELECT alias_domain,target_domain,modified,active
    FROM %table_alias_domain
    WHERE alias_domain=? OR target_domain=?
    ORDER BY alias_domain
    LIMIT ? OFFSET ?",
    # TODO take care of Postgres
    #select_by_target_pg=> "SELECT alias_domain,target_domain,extract(epoch from modified) as modified, active
    #FROM %table_alias_domain
    #WHERE alias_domain=? OR target_domain=?
    #ORDER BY alias_domain
    #LIMIT ? OFFSET ?",
    # TODO modify result: modified=gmstrftime('%c %Z',$row['modified']);
    #                     active  =('t'==$row['active']) ? 1 : 0;
);

sub select_by_domain {
    my ($self, $domain, $display, $page_size) = @_;
    return Ashafix::Model::query($snippets{select_by_domain}, $domain, $domain, $display, $page_size);
}

1;
