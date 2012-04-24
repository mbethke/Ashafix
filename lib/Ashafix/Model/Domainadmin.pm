package Ashafix::Model::Domainadmin;
#===============================================================================
#
#         FILE:  Domainadmin.pm
#
#  DESCRIPTION:  Domainadmin table
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/11/2011 14:48:05 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use parent 'Ashafix::Model::Base';

our %queries = (
    select_domain_count => "SELECT count(*) FROM %table_domain_admins WHERE username=? AND domain='ALL'",
    check_global_admin  => "SELECT username FROM %table_domain_admins WHERE username=? AND domain='ALL' AND active='1'",
    check_domain_owner  => "SELECT 1 FROM %table_domain_admins WHERE username=? AND (domain=? OR domain='ALL') AND active='1'",
    select_global_admin => "SELECT * FROM %table_domain_admins WHERE username=? AND domain='ALL'",
    insert_domadmin     => "INSERT INTO %table_domain_admins (username,domain,created) VALUES (?,?,NOW())",
    delete_by_user      => "DELETE FROM %table_domain_admins WHERE username=?",
    delete_by_domain    => "DELETE FROM %table_domain_admins WHERE domain=?",
);

1;
