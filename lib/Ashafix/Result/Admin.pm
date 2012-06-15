package Ashafix::Result::Admin;
#===============================================================================
#
#         FILE: Admin.pm
#
#  DESCRIPTION: Class representing an admin
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/15/2012 10:39:33 AM
#     REVISION: ---
#===============================================================================
use Mojo::Base 'Ashafix::Result::Account';

has [qw/ domains domain_count /];

1;
