package Ashafix::Result::Account;
#===============================================================================
#
#         FILE: Account.pm
#
#  DESCRIPTION: An account superclass for mailboxes and admins
#
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/15/2012 12:00:25 PM
#===============================================================================

use Mojo::Base -base;

has [qw/ name password roles created modified active /];

1;
