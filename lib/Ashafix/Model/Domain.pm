package Ashafix::Model::Domain;
#===============================================================================
#
#         FILE:  Domain.pm
#
#  DESCRIPTION:  Domain table
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  21/11/2011 00:30:25 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use parent 'Ashafix::Model::Base';

our %queries = (
    check_domain        => "SELECT 1 FROM %table_domain WHERE domain=?",
    get_domain_props    => "SELECT * FROM %table_domain WHERE domain=?",
    #TODO get_domain_props_pg => "SELECT *, EXTRACT(epoch FROM created) AS uts_created, EXTRACT(epoch FROM modified) AS uts_modified FROM %table_domain WHERE domain=?"
    get_real_domains    => "SELECT domain FROM %table_domain WHERE domain != 'ALL' ORDER BY domain",
    insert              => "INSERT INTO %table_domain
        (domain,description,aliases,mailboxes,maxquota,transport,backupmx,created,modified)
        VALUES (?,?,?,?,?,?,?,NOW(),NOW())",
    delete              => "DELETE FROM %table_domain WHERE domain=?",
    delete_everything   => "DELETE FROM %table_domain",
);

1;
