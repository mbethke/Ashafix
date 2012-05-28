package Ashafix::Controller::Mailbox;
#===============================================================================
#
#         FILE:  Mailbox.pm
#
#  DESCRIPTION:  Controller for operations on mailboxes
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  10/11/2011 10:40:11 AM
#     REVISION:  ---
#===============================================================================
use 5.010;
use strict;
use warnings;
use Mojo::Base 'Ashafix::Controller::MailAddress';
use List::MoreUtils qw/ any /;
use Try::Tiny;

sub delete {
    my $self = shift;
    my $mailbox = $self->param('mailbox');
    my $domain = $self->param('domain');
    my $model = $self->model();

    $self->_check_alias_permissions($mailbox, $domain);
    $model->begin;
    $self->_delete_alias($mailbox, $domain);
    if($self->_delete_mailbox($mailbox, $domain)) {
        $self->_delete_mailbox_related($mailbox, $domain);
        $model->commit;
    } else {
        $model->rollback;
    }

    $self->redirect_to('virtual-list');
}

# Provide an empty form for creating a new mailbox
sub form {
    my $self = shift;
    my %params = ( $self->_get_common_params, active  => 1 );

    ($params{domain}, $params{quota}) = $self->_permitted_domain(@params{qw/ domain domains /});

    return $self->_render(\%params);
}

# Create mailbox according to POSTed parameters
sub create {
    my $self = shift;
    my %params = $self->_get_extended_params; 

    $self->_create_check_params(\%params) or return $self->_render(\%params);
    unless(any { $params{$_} } qw/ username_error password_error quota_error /) {
        $self->_create_mailbox(\%params);
    }

    return $self->_render(\%params);
}

sub edit {
    my $self = shift;
    my %params = $self->_get_extended_params;
    my $model = $self->model('mailbox');

    return $self->redirect_to('virtual-list') if $self->param('cancel');

    my $userdata = $model->get_mailbox_data(@params{qw/ username domain /})->hash;
    #  TODO user-friendly/localized error
    die("Invalid username `$params{username}'; user does not exist in mailbox table") unless defined $userdata->{username};

    ($params{password}) = $self->_check_password(\%params);

    if($self->cfg('quota') and !$self->check_quota(@params{qw/ quota domain /})) {
        # Not enough quota for domain to accomodate the specified amount
        $params{quota_error} = $self->l('pEdit_mailbox_quota_text_error');
        warn "quota_error: $params{quota_error}";
        return $self->_render(\%params, mode => 'edit');
    }

    my $quota = defined $params{quota} ? $self->multiply_quota($params{quota}) : 0; 
    $params{active} = 'on' eq $params{active};
    my $local_part = $params{username} =~ /(.*)\@/ ? $1 : $params{username};
    warn "Updating where username=$params{username}/domain=$params{domain}: " . 
        join(',', map { "`$_'" } $quota, $local_part, @params{qw/ name active password username domain /});
    my $rows = $model->update($quota, $local_part, @params{qw/ name active password username domain /})->rows;

    if(1 == $rows and
        $self->mailbox_postedit($params{username}, $params{domain} ,$userdata->{maildir}, $quota)) {
        # Edit successful
        $self->db_log ($params{domain}, 'edit_mailbox', $params{username});
    } else {
         $self->flash_error($self->l('pEdit_mailbox_result_error'));
    }
    $self->redirect_to('virtual-list');
}

# Provide a form pre-filled in edit mode
sub editform {
    my $self = shift;
    my %params = ( $self->_get_common_params, username => lc $self->param('username') );
    my $model = $self->model('mailbox');

    unless($self->check_domain_owner($self->auth_get_username, $params{domain})) {
        $self->flash_error($self->l('pEdit_mailbox_domain_error') . $params{domain});
        return $self->redirect_to('virtual-list');
    }

    my $userdata = $model->get_mailbox_data(@params{qw/ username domain /})->hash;
    #  TODO user-friendly/localized error
    die("Invalid username; user does not exist in mailbox table") unless defined $userdata->{username};

    $params{name}       = $userdata->{name};
    $params{active}     = $userdata->{active};   # TODO support Postgres
    $params{quota}      = $self->divide_quota($userdata->{quota});
    $params{maxquota}   = $self->_allowed_quota($params{domain}, $userdata->{quota});
    return $self->_render(\%params, mode => 'edit');
}

# Get request parameters needed by all creation methods
sub _get_common_params {
    my $self = shift;
    return (
        domain  => $self->req->param('domain') // '',
        domains => [ $self->get_domains_for_user ],  # TODO filter for alias domains
    );
}

# Get all request parameters for the create/edit methods
sub _get_extended_params {
    my $self = shift;
    my $req = $self->req;
    my $username = $req->param('username') // '';
    my %params =  $self->_get_common_params;

    $params{$_} = $req->param($_) // '' foreach(qw/ password password2 name quota active send_mail /);
    $params{username} = lc $username;
    $params{username_dom} = "$username\@$params{domain}";
    return %params;
}

# Render the one template common to all methods with parameters passed in as a
# hashref and optional extra named arguments
sub _render {
    my $self =  shift;
    my $params = shift;
    use Data::Dumper; warn Dumper($params);
    return $self->render(
        template        => 'mailbox/edit',
        mode            => 'create',
        %$params, @_
    );
}

# Check that $domain is defined and in @$alldomains. If either is not the case,
# use first domain from @$alldomains and show an error. Also get this domain's
# allowable quota.
sub _permitted_domain {
    my ($self, $domain, $alldomains) = @_;

    $domain = $domain // $alldomains->[0];
    unless(any { $_ eq $domain } @$alldomains) {
        # TODO localize
        $self->show_error("Invalid domain name selected, or you tried to select a domain you are not an admin for!");
        $domain = $alldomains->[0];
    }
    # TODO check for remaining domain quota, reduce $tQuota if it is
    # lower Note: this is dependent on the domain, which means to do it
    # correct we'd have to remove the domain dropdown and hardcode the
    # domain name from ?domain=... _allowed_quota() will provide the
    # maximum allowed quota 
    # TODO WTF does that mean?
    return ($domain, $self->_allowed_quota($domain, 0));
}

# Check user name for validity and domain ownership
sub _create_check_username {
    my ($self, $par) = @_;

    length $par->{username} and
    $self->check_domain_owner($par->{username_dom}, $par->{domain}) and
    $self->check_email_validity($par->{username_dom}) and
    return 1;
    $par->{username_error} = $self->l('pCreate_mailbox_username_text_error1');
    warn "username_error for `$par->{username_dom}': $par->{username_error}";
    return;
}

# Check passwords for equality and validate them. If passwords are empty and
# the `generate_password' config option is set, auto-generate one. Returns vlid
# password and autogenerated flag or empty list on error.
sub _check_password {
    my ($self, $par) = @_;
    my ($pass1, $pass2) = @$par{qw/ password password2 /};
    my $pass_generated;

    if(not length $pass1 and not length $pass2 and $self->cfg('generate_password')) {
        $pass1 = $self->generate_password; 
        $pass_generated = 1;
    } elsif(not length $pass1 or not length $pass2 or $pass1 ne $pass2) {
        $par->{password_error} = $self->l('pCreate_mailbox_password_text_error');
        warn "password_error: $par->{password_error}";
        return;
    } else {
        try {
            $self->validate_password($pass1)
        } catch {
            # TODO localize
            $par->{password_error} = "Password check failed: $@";
            warn "password_error: $par->{password_error}";
        };
        return if $par->{password_error};
    }
    return ($pass1, $pass_generated);
}

# Check all mailbox creation arguments for validity
sub _create_check_params {
    my ($self, $par) = @_;

    $self->_create_check_username($par) or return;

    unless($self->_check_mailbox_creation($par->{domain})) {
        # Maximum number of mailboxes reached for this domain
        $par->{username_error} = $self->l('pCreate_mailbox_username_text_error3');
        warn "username_error: $par->{username_error}";
        return;
    }

    ($par->{password}, $par->{pass_generated}) =
        $self->_check_password($par) or return;

    if($self->cfg('quota') and !$self->check_quota(@$par{qw/ quota domain /})) {
        # Not enough quota for domain to accomodate the specified amount
        $par->{quota_error} = $self->l('pCreate_mailbox_quota_text_error');
        warn "quota_error: $par->{quota_error}";
        return;
    }

    if(@{[$self->model('alias')->get_goto_by_address($par->{username_dom})->flat]}) {
        # Mailbox already exists
        $par->{username_error} = $self->l('pCreate_mailbox_username_text_error2');
        warn "username_error: $par->{username_error}";
        return;
    }
    return 1;
}

sub _create_mailbox_directory_name {
    my ($self, $par) = @_;

    if($self->cfg('maildir_name_hook')) {
        # TODO call creation hook here
        die "maildir creation hook unimplemented";
    } elsif($self->cfg('domain_path')) {
        my $second_dir = $self->cfg('domain_in_mailbox') ? 'username_dom' : 'username';
        return "$par->{domain}/$par->{second_dir}/";
    } else {
        return $par->{username_dom} . '/';
    }
}

# After all parameters have been checked without error, actually create the mailbox
sub _create_mailbox {
    my ($self, $par) = @_;
    my $maildir = $self->_create_mailbox_directory_name;

    my $password = $self->app->pacrypt($par->{password});
    $par->{quota} = $self->multiply_quota($par->{quota}) // 0;

    # TODO handle Postgres (0,1)=>('f','t');
    $par->{active} = 'on' eq $par->{active} ? 1 : 0;
    # TODO support Postgres' transactions (db_query('BEGIN');)

    if(1 == $self->model('alias')->insert(@$par{qw/ username_dom username_dom domain active /})->rows) {
        # INSERT was successful
        if(1 == $self->model('mailbox')->insert(@$par{qw/ username_dom password name maildir username quota domain active /})->rows) {
            # TODO db_query('COMMIT');
            $self->db_log($par->{domain}, 'create_mailbox', $par->{username_dom});
            $par->{quota} = $self->_allowed_quota($par->{domain}, 0);
            $self->_welcome_mail($par->{username_dom}) if $par->{send_mail} eq 'on';

            my $showpass = ($par->{pass_generated} or $self->cfg('show_password')) ? " / $password" : '';
            my $folders_ok = $self->_create_mailbox_subfolders($par->{username_dom}, $password);
            # TODO get rid of HTML here
            $self->show_info($self->l($folders_ok ?
                    'pCreate_mailbox_result_success' :
                    'pCreate_mailbox_result_succes_nosubfolders'
                ) . "<br />($par->{username}$showpass)"
            );
        } else {
            # TODO should we try to manually roll back the previous INSERT for MySQL?
            # TODO db_query('ROLLBACK');
            # TODO get rid of HTML here
            $self->show_error($self->l('pCreate_mailbox_result_error') . "<br />($par->{username_dom})");
            return;
        }
    } else {
        # TODO get rid of HTML here
        $self->show_error($self->l('pAlias_result_error') . "<br />($par->{username_dom} -> $par->{username_dom})");
        # TODO db_query('ROLLBACK');
        return;
    }
    return 1;
}

sub _welcome_mail {
    my ($self, $to) = @_;
    my $ok = 1;

    try {
        eval "use MIME::Lite";
        die if $@;
    } catch {
        $self->show_error($self->l('pSendmail_result_error') . "(module MIME::Lite not installed)");
        $ok = 0
    };
    return unless $ok;

    my $msg = MIME::Lite->new(
        From    => $self->cfg('admin_email') || $self->auth_get_username,
        To      => $to,
        Subject => $self->l('pSendmail_subject_text'),
        Type    => 'text/plain',
        Data    => $self->cfg('welcome_text'), 
    );
    try {
        $msg->send('smtp', $self->cfg('smtp_server') || 'localhost',
            Port    => $self->cfg('smtp_port') || 25,
            Timeout => 30,
        );
        $self->show_info($self->l('pSendmail_result_success'));
    } catch {
        $self->show_error($self->l('pSendmail_result_error') . "($_)");
    };
}

sub _allowed_quota {
    my ($self, $domain, $current_user_quota) = @_;
    my $dprops = $self->get_domain_properties($domain);
    my $maxquota = $dprops->{maxquota};

    if($self->cfg('domain_quota') and $dprops->{quota}) {
        my $dquota = $dprops->{quota} - $self->divide_quota($dprops->{quota_sum} - $current_user_quota);
        $maxquota = $dquota if($dquota < $maxquota or 0 == $maxquota);
    }
    return $maxquota;
}

sub _check_mailbox_creation {
    my ($self, $domain) = @_;
    my $limit = $self->get_domain_properties($domain);
    
    return 1 if 0 == $limit->{mailboxes};
    return   if 0 >  $limit->{mailboxes};
    return   if $limit->{mailbox_count} >= $limit->{mailboxes};
    return 1;
}

# Delete a mailbox without any transactional protection; run postdeletion script
sub _delete_mailbox {
    my ($self, $mailbox, $domain) = @_;

    # Do we have a mailbox?
    @{[$self->model('mailbox')->check_mailbox($mailbox, $domain)->flat]} or return;
    my $deleted = $self->model('mailbox')->delete_by_username($mailbox, $domain)->rows == 1;
    my $postdel = $self->_mailbox_postdeletion($mailbox, $domain);
    unless($deleted and $postdel) {
        my $msg = $self->l('pDelete_delete_error') . "$mailbox (";
        unless($deleted) {
            $msg .= 'mailbox';
            $msg .= ', ' unless $postdel;
        }
        $msg .= 'post-deletion' unless $postdel;
        $self->show_error($msg);
        return;
    }
    $self->db_log($domain, 'delete_mailbox', $mailbox);
}

# TODO obsolete this using ON DELETE CASCADE in the DB
sub _delete_mailbox_related {
    my ($self, $mailbox, $domain) = @_;

    @{[$self->model('vacation')->check_by_mbox($mailbox, $domain)]} and
        $self->model('vacation')->delete_vacation($mailbox, $domain);
        # Skip this, use ON DELETE CASCADE everywhere
#       db_query ("DELETE FROM $table_vacation_notification WHERE on_vacation ='$fDelete' "); /* should be caught by cascade, if PgSQL */
    @{[$self->model('quota')->find_by_user($mailbox)]} and
        $self->model('quota')->delete($mailbox);
}

# TODO implement
sub _mailbox_postdeletion {
    warn "TODO: Controller::Mailbox::_mailbox_postdeletion";
}

# Called after a mailbox has been altered in the DBMS.
sub mailbox_postedit {
    my ($self, $username, $domain,  $maildir, $quota) = @_;
    warn "TODO: Controller::Mailbox::_mailbox_postedit";
}

=cut
    if (empty($username) || empty($domain) || empty($maildir)) {
        trigger_error('In '.__FUNCTION__.': empty username, domain and/or maildir parameter',E_USER_ERROR);
        return FALSE;
    }

    global $CONF;
    $confpar='mailbox_postedit_script';

    if (!isset($CONF[$confpar]) || empty($CONF[$confpar])) return TRUE;

    $cmdarg1=escapeshellarg($username);
    $cmdarg2=escapeshellarg($domain);
    $cmdarg3=escapeshellarg($maildir);
    if ($quota <= 0) $quota = 0;
    $cmdarg4=escapeshellarg($quota);
    $command=$CONF[$confpar]." $cmdarg1 $cmdarg2 $cmdarg3 $cmdarg4";
    $retval=0;
    $output=array();
    $firstline='';
    $firstline=exec($command,$output,$retval);
    if (0!=$retval) {
        error_log("Running $command yielded return value=$retval, first line of output=$firstline");
        print '<p>WARNING: Problems running mailbox postedit script!</p>';
        return FALSE;
    }

    return TRUE;
}
=cut
1;
