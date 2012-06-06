package Ashafix::Controller::MailAddress;
#===============================================================================
#
#         FILE:  MailAddress.pm
#
#  DESCRIPTION:  Common base class for Mailbox and Alias controllers that share
#                some functionality
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  10/27/2011 02:39:52 AM
#     REVISION:  ---
#===============================================================================

use 5.010;
use strict;
use warnings;
use Mojo::Base 'Ashafix::Controller';

# Delete an alias transactionally after checking permission.
sub delete_alias {
    my ($self, $alias, $domain) = @_;

    $self->_check_alias_permissions($alias, $domain);
    $self->model()->begin;
    $self->_delete_alias($alias, $domain);
    $self->model()->commit;
}

# Delete an alias. No transactions and permission checking,
# use delete_alias from subclasses
sub _delete_alias {
    my ($self, $alias, $domain) = @_;
    my $model = $self->model('alias');
    if(@{[$model->check_alias($alias, $domain)->flat]}) {
        $model->delete_by_alias($alias, $domain);
        $self->db_log($domain, 'delete_alias', $alias);
        return 1;
    }
    return;
}

# Check permission to manipulate a mailbox or alias
sub _check_alias_permissions {
    my ($self, $alias, $domain) = @_;
    my $user = $self->session('user')->{name};

    unless($self->check_domain_owner($user, $domain)) {
        $self->show_error_l('pDelete_domain_error', "($domain)");
        return;
    }
    unless($self->check_alias_owner($user, $alias)) {
        $self->show_error_l('pDelete_alias_error', "($alias)");
        return;
    }
    return 1;
}

1;
