package Ashafix::Model::Mailbox;
#===============================================================================
#
#         FILE:  Mailbox.pm
#
#  DESCRIPTION:  Mailbox table
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/21/2011 12:49:18 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use parent 'Ashafix::Model::Base';

our %queries = (
    check_mailbox           => "SELECT 1 FROM %table_mailbox WHERE username=? AND domain=?",
    get_password            => "SELECT password FROM %table_mailbox WHERE username=?",
    get_mailbox_data        => "SELECT * FROM %table_mailbox WHERE username=? AND domain=?",
    update                  => "UPDATE %table_mailbox SET quota=?,local_part=?,name=?,active=?,password=? WHERE username=? AND domain=?",
 count_domain_mailboxes  => "SELECT COUNT(*) FROM %table_mailbox WHERE domain=?",
    get_domain_quota        => "SELECT SUM(quota) FROM %table_mailbox WHERE domain=?",
    delete_by_username      => "DELETE FROM %table_mailbox WHERE username=? AND domain=?",
    delete_by_domain        => "DELETE FROM %table_mailbox WHERE domain=?",
    insert                  => "INSERT INTO %table_mailbox
        (username,password,name,maildir,local_part,quota,domain,created,modified,active)
        VALUES (?,?,?,?,?,?,?,NOW(),NOW(),?)",
    update_password         => "UPDATE %table_mailbox SET password=?,modified=NOW() WHERE username=?",
    delete_everything       => "DELETE FROM %table_mailbox",
);

1;
