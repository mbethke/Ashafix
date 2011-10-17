package Ashafix::Controller;
#===============================================================================
#
#         FILE:  Controller.pm
#
#  DESCRIPTION:  Base class for all Ashafix controllers. Collects a few
#                utility methods
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/12/2011 03:58:21 PM
#     REVISION:  ---
#===============================================================================

use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5;
use URI::Escape;

# Get the currently logged in user
sub auth_get_username {
    my $self = shift;
    my $user = $self->session('user') or return;
    return $user->{name};
}

# Takes a user role and returns a boolean indicating whether current user
# has this role
sub auth_has_role {
    my ($self, $role) = @_;
    my $user = $self->session('user') or return;
    return $user->{roles}{$role};
}

# Requires user to have a certain role. On failure, false is returned
# and the user redirected to login
sub auth_require_role {
    my ($self, $role) = @_;
    return unless $self->auth_require_login;
    return 1 if $self->auth_has_role($role);
    $self->redirect_to(named => 'login');
    return;
}

# Require that user be logged in. Redirect to login if not.
sub auth_require_login {
    my $self = shift;
    my $user = $self->session('user');
    return 1 if defined $user->{name};
    $self->redirect_to(named => 'login');
    return;
}

# Get account properties for a named account as a hash reference
sub get_admin_properties {
    my ($self, $name) = @_;
    my $props = {};

    if(defined $self->model('domainadmin')->select_global_admin->list) {
        # global admin
        $props->{domain_count} = 'ALL';
    } else {
        # normal domain admin
        ($props->{domain_count}) = $self->model('domainadmin')->select_domain_count($name)->list;
    }
    
    if(my $row = $self->model('admin')->select_admin($name)->hash) {
        $props->{$_} = $row->{$_} foreach(qw/created modified active/);
        # TODO handle pgsql?
        #    if ('pgsql'==$CONF['database_type']) {
        #        $list['active'] = ('t'==$row['active']) ? 1 : 0;
        #        $list['created']= gmstrftime('%c %Z',$row['uts_created']);
        #        $list['modified']= gmstrftime('%c %Z',$row['uts_modified']);
        #    }
    }
    return $props;
}

sub generate_password {
    return substr(Digest::MD5::md5_base64(rand),0,10)
}

sub delete_alias_or_mailbox {
    my ($self, $addr) = @_;
    my $user = $self->auth_get_username;

    $self->check_mailbox_owner($user, $addr) or return $self->render(
        template => 'message',
        # TODO get rid of this HTML crap
        tMessage => $self->l('pDelete_domain_error') . "<b>$addr</b>!</span>",
    );
    $self->check_alias_owner($user, $addr) or return $self->render(
        template => 'message',
        # TODO get rid of this HTML crap
        tMessage => $self->l('pDelete_alias_error') . "<b>$addr</b>!</span>",
    );
    # TODO finish
}

sub get_domain_properties {
    my ($self, $domain) = @_;
    my %props;
    my $res = $self->model('domain')->get_domain_props($domain)->hash;
    %props = (
        alias_count   => $self->model('alias')->count_domain_aliases($domain)->flat,
        mailbox_count => $self->model('mailbox')->count_domain_mailboxes($domain)->flat,
        quota_sum     => $self->model('mailbox')->quota_sum($domain)->flat,
        map { $_ => $res->{$_} } qw/ description aliases mailboxes maxquota quota transport backupmx created modified active /
        # TODO if ($CONF['database_type'] == "pgsql") {
        # $list['active']=('t'==$row['active']) ? 1 : 0;
        # $list['backupmx']=('t'==$row['backupmx']) ? 1 : 0;
        # $list['created']= gmstrftime('%c %Z',$row['uts_created']);
        # $list['modified']= gmstrftime('%c %Z',$row['uts_modified']);
        # }
    );
    $props{alias_count} -= $props{mailbox_count}; 
    return \%props;
}

1;
