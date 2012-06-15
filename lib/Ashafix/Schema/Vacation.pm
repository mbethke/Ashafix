package Ashafix::Schema::Vacation;
#===============================================================================
#
#         FILE:  Vacation.pm
#
#  DESCRIPTION:  Vacation model, uses vacation and vacation_notification tables
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  10/29/2011 03:23:39 PM
#     REVISION:  ---
#===============================================================================
use 5.010;
use strict;
use warnings;
use parent 'Ashafix::Schema::Base';

our %queries = (
    check_by_mbox       => 'SELECT 1 FROM %table_vacation WHERE email=? AND domain=?',
    delete_vacation     => 'DELETE FROM %table_vacation WHERE email=? AND domain=?',
    delete_everything   => 'DELETE FROM %table_vacation',
);

1;

