package Ashafix::Model::Alias;
#===============================================================================
#
#         FILE:  Alias.pm
#
#  DESCRIPTION:  Mailbox alias table
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/21/2011 12:49:04 PM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use parent 'Ashafix::Model::Base';

our %queries = (
    get_by_address          => "SELECT * FROM %table_alias WHERE address=? AND domain=?",
    get_address_2           => "SELECT address FROM %table_alias WHERE address IN (?,?)",
    get_address_3           => "SELECT address FROM %table_alias WHERE address IN (?,?,?)",
    get_goto_by_address     => "SELECT goto FROM %table_alias WHERE address=?",
    check_alias             => "SELECT 1 from %table_alias WHERE address=? AND domain=?",
    count_domain_aliases    => "SELECT COUNT(*) FROM %table_alias WHERE domain=?",
    delete_by_domain        => "DELETE FROM %table_alias WHERE domain=?",
    delete_by_alias         => "DELETE FROM %table_alias WHERE address=? AND domain=?",
    insert                  => "INSERT INTO %table_alias
        (address,goto,domain,created,modified,active) VALUES (?,?,?,NOW(),NOW(),?)",
);

1;
