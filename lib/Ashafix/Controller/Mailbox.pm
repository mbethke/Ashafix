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

    if(length $params{username}
            and $self->check_domain_owner($params{username_dom}, $params{domain}))
    {
        try {
            $self->model('mailbox')->create(\%params);
        } catch {
            $self->show_error($self->handle_exception($_));
        };
    } else {
        $self->show_error_l('pCreate_mailbox_username_text_error1');
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
         $self->flash_error_l('pEdit_mailbox_result_error');
    }
    $self->redirect_to('virtual-list');
}

# Provide a form pre-filled in edit mode
sub editform {
    my $self = shift;
    my %params = ( $self->_get_common_params, username => lc $self->param('username') );
    my $model = $self->model('mailbox');

    unless($self->check_domain_owner($self->auth_get_username, $params{domain})) {
        $self->flash_error_l('pEdit_mailbox_domain_error', $params{domain});
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

sub _welcome_mail {
    my ($self, $to) = @_;
    my $ok = 1;

    try {
        eval "use MIME::Lite";
        die if $@;
    } catch {
        $self->show_error_l('pSendmail_result_error' . "(module MIME::Lite not installed)");
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
        $self->show_info_l('pSendmail_result_success');
    } catch {
        $self->show_error_l('pSendmail_result_error', "($_)");
    };
}

sub _allowed_quota {
    my ($self, $domain, $current_user_quota) = @_;
    my $dom = $self->model('domain')->load($domain);
    my $maxquota = $dom->maxquota;

    if($self->cfg('domain_quota') and $dom->quota) {
        my $dquota = $dom->quota - $self->divide_quota($dom->quota_sum - $current_user_quota);
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
