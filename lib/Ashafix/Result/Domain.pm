package Ashafix::Result::Domain;
#===============================================================================
#
#         FILE: Domain.pm
#
#  DESCRIPTION: Domain result class
#
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/15/2012 01:29:46 PM
#===============================================================================
use Mojo::Base -base;

has [ qw/
    domain description
    aliases alias_count
    mailboxes mailbox_count
    maxquota quota quota_sum
    transport backupmx
    created modified
    active / ];
1;

