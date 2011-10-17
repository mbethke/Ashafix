package Ashafix::Model::Aliasdomain;
#===============================================================================
#
#         FILE:  Aliasdomain.pm
#
#  DESCRIPTION:  Domain alias table
#
#        FILES:  ---
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
    select_by_target    => "SELECT alias_domain,target_domain,modified,active
    FROM %table_alias_domain
    WHERE target_domain=?
    ORDER BY alias_domain LIMIT ?,?",
    # TODO take care of Postgres
    #select_by_target_pg=> "SELECT alias_domain,target_domain,extract(epoch from modified) as modified, active
    #FROM %table_alias_domain
    #WHERE target_domain=?
    #ORDER BY alias_domain LIMIT ? OFFSET ?",
    # TODO modify result: modified=gmstrftime('%c %Z',$row['modified']);
    #                     active  =('t'==$row['active']) ? 1 : 0;

    select_by_alias     => "SELECT alias_domain,target_domain,modified,active
    FROM %table_alias_domain
    WHERE alias_domain=?",
    # TODO take care of Postgres
    # select_by_alias_pg  => "SELECT alias_domain,target_domain,extract(epoch from modified) as modified,active
    #FROM %table_alias_domain
    #WHERE alias_domain=?",
    # TODO modify result: modified=gmstrftime('%c %Z',$row['modified']);
    #                     active  =('t'==$row['active']) ? 1 : 0;

    delete_by_alias     => "DELETE FROM %table_alias_domain WHERE alias_domain=?",
);



1;
