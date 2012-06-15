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

# Show error/info in page header of current or redirected-to page
sub show_error  { shift->_add_show( error => join('', @_)) }
sub show_info   { shift->_add_show( info  => join('', @_)) }
sub flash_error { shift->_add_flash(error => join('', @_)) }
sub flash_info  { shift->_add_flash(info  => join('', @_)) }
# Localizing versions of the above
sub show_error_l  { shift->_localize(_add_show  => error => @_) }
sub show_info_l   { shift->_localize(_add_show  => info  => @_) }
sub flash_error_l { shift->_localize(_add_flash => error => @_) }
sub flash_info_l  { shift->_localize(_add_flash => info  => @_) }
sub _localize {
    my ($self, $func, $what, $key) = splice @_,0,4;
    print STDERR "_localize($self, $func, $what, $key)\n";
    $self->$func($what => join('', $self->l($key), @_));
}

sub _add_show   { push @{$_[0]->stash($_[1])}, $_[2] }
sub _add_flash  {
    my ($self, $what, $msg) = @_;
    my $msgs = $self->flash($what) // [];
    $self->flash($what => [@$msgs, $msg]);
}
# Get the currently logged in user
sub auth_get_username {
    my $self = shift;
    my $user = $self->session('user') or return;
    return $user->{name};
}


# Takes a user name and a password and returns a user info structure
# or undef on verification failure
# TODO put this into the model and make the return a proper user object
sub verify_account {
    my ($self, $user, $pass) = @_;
    my $roles;
    return unless defined $user and defined $pass;
    if($self->_check_password($user, $pass, 1)) {
        print STDERR "checked password\n";
        # Found admin user
        $roles = { admin => 1, globaladmin => $self->_check_global_admin($user) };
        print STDERR "checked password\n";
    } elsif($self->_check_password($user, $pass, 0)) {
        # Found regular user
        $roles = { user => 1 };
    } else {
        # Verification unsuccessful
        return;
    }
    return { name => $user, roles => $roles };
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

sub generate_password {
    return substr(Digest::MD5::md5_base64(rand),0,10)
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

# Takes a username/password pair and a boolean value indicating whether
# to look for admins (true) or users (false). Returns a boolean value
# for verification status.
sub _check_password {
    my ($self, $user, $pass, $admin) = @_;
    # TODO simplify after updating the mailbox model
    my $stored_pass = $admin ? $self->model('admin')->load($user)->password : $self->model('mailbox')->load($user)->password;
    return defined $stored_pass && $self->app->pacrypt($pass, $stored_pass) eq $stored_pass;
}

# Return a true value if the passed-in user is a global admin
sub _check_global_admin { defined $_[0]->schema('domainadmin')->check_global_admin($_[1])->list }

1;
