package Ashafix::Model::Misc;
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
use parent 'Ashafix::Model::Base';

my $initialized;
our %queries = (
    encrypt        => "SELECT ENCRYPT(?)",
    encrypt_salted => "SELECT ENCRYPT(?, ?)",
);

1;
