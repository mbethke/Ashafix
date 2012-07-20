package Ashafix::Result::Aliasdomain;
#===============================================================================
#
#         FILE: Aliasdomain.pm
#
#  DESCRIPTION: Alias domain result class
#
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/15/2012 01:29:46 PM
#     REVISION: ---
#===============================================================================
use Mojo::Base -base;

has [qw/ alias_domain target_domain created modified active /];

1;

