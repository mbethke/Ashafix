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
use base 'Ashafix::Model::Base';

our %queries = (
    count_domain_mailboxes  => "SELECT COUNT(*) FROM %table_mailbox WHERE domain=?",
    get_domain_quota        => "SELECT SUM(quota) FROM %table_mailbox WHERE domain=?",
    delete_by_domain        => "DELETE FROM %table_mailbox WHERE domain=?",
);

1;
