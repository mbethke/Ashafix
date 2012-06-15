package Ashafix::Schema::Admin;
#===============================================================================
#
#         FILE:  Admin.pm
#
#  DESCRIPTION:  Admin table
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/11/2011 11:22:02 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use parent 'Ashafix::Schema::Base';

our %queries = (
    get_password        => "SELECT password FROM %table_admin WHERE username=? AND active='1'",
    get_all_admin_names => "SELECT username FROM %table_admin ORDER by username",
    insert_admin        => "INSERT INTO %table_admin (username,password,created,modified) VALUES (?,?,NOW(),NOW())",
    # TODO select_admin_pgsql => "SELECT *, EXTRACT(epoch FROM created) AS uts_created, EXTRACT (epoch FROM modified) AS uts_modified FROM %table_admin WHERE username=?"
    select_admin        => "SELECT * FROM %table_admin WHERE username=?",
    delete              => "DELETE FROM %table_admin WHERE username=?",
    update_password     => "UPDATE %table_admin SET password=?,modified=NOW() WHERE username=?",
    delete_everything   => "DELETE FROM %table_admin",
);

1;
