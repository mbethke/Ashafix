package Ashafix::Model::Log;
#===============================================================================
#
#         FILE:  Log.pm
#
#  DESCRIPTION:  Log table
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/22/2011 02:29:55 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use base 'Ashafix::Model::Base';

our %queries = (
    delete              => "DELETE FROM %table_log WHERE domain=?",
    insert              => "INSERT INTO %table_log VALUES (NOW,?,?,?,?)",
);

1;
