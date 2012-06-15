package Ashafix::Schema::Log;
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
use parent 'Ashafix::Schema::Base';

our %queries = (
    insert              => "INSERT INTO %table_log VALUES (NOW(),?,?,?,?)",
    delete              => "DELETE FROM %table_log WHERE domain=?",
    delete_everything   => "DELETE FROM %table_log",
);

1;
