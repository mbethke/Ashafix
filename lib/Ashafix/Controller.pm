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
use 5.010;
use Mojo::Base 'Mojolicious::Controller';
use Digest::MD5;
use URI::Escape;
use Email::Valid;
use Carp;

sub show_error  { $_[0]->stash(error => $_[1]) }
sub show_info   { $_[0]->stash(info  => $_[1]) }
sub flash_error { $_[0]->flash(error => $_[1]) }
sub flash_info  { $_[0]->flash(info  => $_[1]) }

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
    # TODO flash() "Insufficient privileges" or something?
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

# Check a password's kwalitee. If Crypt::Cracklib is not available, anything
# with at least 6 characters is fine.
# Dies with a reason in $@ on check failure.
sub validate_password {
    my ($self, $pw) = @_;
    # Don't bother with all these hand-written regexen and use trusty ol'
    # Cracklib if available. If not, Bad Luck[tm].
    eval "use Crypt::Cracklib ();";
    if($@) {
        6 <= length $pw and return 1;
        die "it is too short\n";
    }
    my $result = Crypt::Cracklib::fascist_check($pw);
    die "$result\n" unless $result eq 'ok';
}

sub get_domain_properties {
    my ($self, $domain) = @_;
    my %props;
    my $res = $self->model('domain')->get_domain_props($domain)->hash;
    %props = (
        alias_count   => $self->model('alias')->count_domain_aliases($domain)->flat->[0],
        mailbox_count => $self->model('mailbox')->count_domain_mailboxes($domain)->flat->[0],
        quota_sum     => $self->model('mailbox')->get_domain_quota($domain)->flat->[0],
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

sub get_domains_for_user {
    my $self = shift;
    $self->auth_has_role('globaladmin') and return $self->model('domain')->get_real_domains->flat;
    return $self->model('domain')->get_domains_for_admin($self->auth_get_username)->flat;
}

# Recalculate mailbox quota to bytes
sub divide_quota {
    my ($self, $quota) = @_;

    return unless defined $quota;
    return $quota if -1 == $quota;
    return sprintf("%.2d", ($quota / $self->cfg('quota_multiplier')) + 0.05);
}

# Recalculate mailbox quota to megabytes
sub multiply_quota {
    my ($self, $quota) = @_;

    return unless defined $quota;
    print STDERR "multiply_quota(`$quota')\n";
    return $quota if -1 == $quota;
    return $quota * $self->cfg('quota_multiplier');
}

sub check_domain_owner {
    my ($self, $user, $domain) = @_;

    if($self->auth_has_role('globaladmin')) {
        # Global admins "own" every domain, so just check that domain actually exists
        @{[$self->model('domain')->check_domain($domain)->flat]} and return 1;
        $self->show_error("Domain `$domain' does not exist");
        return;
    }
    my @doms = $self->model('domainadmin')->check_domain_owner($user, $domain)->flat->[0] and return 1;
    return;
}

# Check validity of an email address
# Returns true on success , dies on error with a localized error message in $@
sub check_email_validity {
    my ($self, $uname) = @_;

    my $mvalid = Email::Valid->new(
        -mxcheck => $self->cfg('emailcheck_resolve_domain'),
        -tldcheck => 1
    );
    warn "checking mail address `$uname'";
    return 1 if $mvalid->address($uname);

    my $err;
    (my $domainpart = $uname) =~ s/.*\@//;
    given($mvalid->details) {
        when('fqdn')    { $err = sprintf($self->l('pInvalidDomainRegex'), $domainpart) }
        when('mxcheck') { $err = sprintf($self->l('pInvalidDomainDNS'), $domainpart)   }
        default         { $err = $self->l('pInvalidMailRegex') . ": `$uname'"  }
    }
    $self->show_error($err);
    return;
}

sub check_alias_owner { 
    my ($self, $username, $alias) = @_;

    return 1 if $self->auth_has_role('globaladmin');

    my ($localpart) = split /\@/, $alias;
    return if(!$self->cfg('special_alias_control') and exists $self->cfg('default_aliases')->{$localpart});
    return 1;
}

# Log actions to database
# Call: db_log (string domain, string action, string data)
# Possible actions are:
# 'create_domain'
# 'create_alias'
# 'create_alias_domain'
# 'create_mailbox'
# 'delete_domain'
# 'delete_alias'
# 'delete_alias_domain'
# 'delete_mailbox'
# 'edit_domain'
# 'edit_alias'
# 'edit_alias_state'
# 'edit_alias_domain_state'
# 'edit_mailbox'
# 'edit_mailbox_state'
# 'edit_password'
#
sub db_log {
    my ($self, $domain, $action, $data) =@_;
    state $logging = $self->cfg('logging');
    state $LOG_ACTIONS = {
        map { $_ => 1 } qw/
        create_alias edit_alias edit_alias_state delete_alias create_mailbox
        edit_mailbox edit_mailbox_state delete_mailbox create_domain edit_domain
        delete_domain create_alias_domain edit_alias_domain_state
        delete_alias_domain edit_password /
    };

    die "Invalid log action `$action'" unless defined $LOG_ACTIONS->{$action};
    return unless $logging;

    my $remote_addr = $self->tx->remote_address;
    my $username = $self->auth_get_username;
    return 1 == $self->model('log')->insert("$username ($remote_addr)", $domain, $action, $data)->rows;
}

1;
