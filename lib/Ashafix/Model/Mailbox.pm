package Ashafix::Model::Mailbox;
#===============================================================================
#
#         FILE: Mailbox.pm
#
#  DESCRIPTION: This class actually describes a regular non-admin user account
#
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/12/2012 08:30:08 AM
#===============================================================================

use Mojo::Base 'Ashafix::Model::Base'; 
use Ashafix::Result::Mailbox;

sub create {
    my ($self, $params) = @_;
    my $r = $self->SUPER::new(@_);

    $self->_create_check_params($params);
    $self->_create_mailbox($params);
}

sub load {
    my ($self, $name) = @_;
    my $r;
    my ($local, $domain) = split /\@/, $name;

    my ($data) = $self->schema('mailbox')->get_mailbox_data($name, $domain)->hashes;
    if($data) {
        # Loading successful, create result object
        $r = Ashafix::Result::Mailbox->new(@_);

        # Copy/set attributes
        $r->name($name);
        $r->$_($data->{$_}) for(qw / name password created modified active /);
        $r->roles({ user => 1 });
    };
    return $r;
}

# Update a mailbox record in the database. Dies with DBI error on failure
# TODO do we need to update other fields apart from passwords?
sub update {
    my ($self, $user) = @_;
    1 == $self->schema('mailbox')->update_password($user->password, $user->name)->rows
        or die $self->schema('')->error;
}

sub delete {
    my ($self, $who) = @_;
    die "unimplemented";
}

# Check all mailbox creation arguments for validity
sub _create_check_params {
    my ($self, $par) = @_;

    $self->check_email_validity($par->{username_dom});

    $self->_check_mailbox_creation($par->{domain})
        or $self->throw('pCreate_mailbox_username_text_error3');

    ($par->{password}, $par->{pass_generated}) = $self->check_password($par);

    # TODO method missing!?
    $self->cfg('quota')
        and !$self->check_quota(@$par{qw/ quota domain /})
    # Not enough quota for domain to accomodate the specified amount
        and $self->throw('pCreate_mailbox_quota_text_error');

    @{[$self->schema('alias')->get_goto_by_address($par->{username_dom})->flat]}
    # Mailbox already exists
        and $self->throw('pCreate_mailbox_username_text_error2');

    return 1;
}

sub _get_mailbox_directory_name {
    my ($self, $par) = @_;
    my $c = $self->controller;

    if($self->cfg('maildir_name_hook')) {
        # TODO call creation hook here
        warn "maildir creation hook unimplemented";
    } elsif($self->cfg('domain_path')) {
        my $second_dir = $self->cfg('domain_in_mailbox') ? 'username_dom' : 'username';
        return "$par->{domain}/$par->{$second_dir}/";
    } else {
        return $par->{username_dom} . '/';
    }
}

# Recalculate mailbox quota to megabytes
sub _multiply_quota {
    my ($self, $quota) = @_;

    return unless defined $quota;
    return $quota if -1 == $quota;
    return $quota * $self->cfg('quota_multiplier');
}


# After all parameters have been checked without error, actually create the mailbox
sub _create_mailbox {
    my ($self, $par) = @_;
    my $c = $self->controller;
    my $maildir = $self->_get_mailbox_directory_name($par);

    my $password = $c->app->pacrypt($par->{password});
    $par->{quota} = $self->_multiply_quota($par->{quota}) // 0;


    $par->{active} = 'on' eq $par->{active} ? 1 : 0;
    # TODO support Postgres' transactions (db_query('BEGIN');)

    if(1 == $self->schema('alias')->insert(@$par{qw/ username_dom username_dom domain active /})->rows) {
        # INSERT was successful
        if(1 == $self->schema('mailbox')->insert(@$par{qw/ username_dom password name maildir username quota domain active /})->rows) {
            # TODO db_query('COMMIT');
            $self->dblog($par->{domain}, 'create_mailbox', $par->{username_dom});
            $par->{quota} = $self->_allowed_quota($par->{domain}, 0);
            $self->_welcome_mail($par->{username_dom}) if $par->{send_mail} eq 'on';

            my $showpass = ($par->{pass_generated} or $self->cfg('show_password')) ? " / $password" : '';
            my $folders_ok = $self->_create_mailbox_subfolders($par->{username_dom}, $password);
            $self->messages($folders_ok ?
                    $self->l('pCreate_mailbox_result_success') :
                    $self->l('pCreate_mailbox_result_succes_nosubfolders'),
                    " ($par->{username}$showpass)"
            );
        } else {
            # TODO db_query('ROLLBACK');
            $self->throw('pCreate_mailbox_result_error', " ($par->{username_dom})");
            return;
        }
    } else {
        $self->throw('pAlias_result_error', " ($par->{username_dom} -> $par->{username_dom})");
        # TODO db_query('ROLLBACK');
        return;
    }
    return 1;
}

# Returns allowable quota for a mailbox, taking domain quota into account
sub _allowed_quota {
    my ($self, $domain, $current_user_quota) = @_;
    my $dprops = $self->_get_domain_properties($domain);
    my $maxquota = $dprops->{maxquota};

    if($self->cfg('domain_quota') and $dprops->{quota}) {
        my $dquota = $dprops->{quota} - $self->divide_quota($dprops->{quota_sum} - $current_user_quota);
        $maxquota = $dquota if($dquota < $maxquota or 0 == $maxquota);
    }
    return $maxquota;
}

sub _check_mailbox_creation {
    my ($self, $domain) = @_;
    my $limit = $self->_get_domain_properties($domain);
    
    return 1 if 0 == $limit->{mailboxes};
    return   if 0 >  $limit->{mailboxes};
    return   if $limit->{mailbox_count} >= $limit->{mailboxes};
    return 1;
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

# Delete a mailbox without any transactional protection; run postdeletion script
sub _delete_mailbox {
    my ($self, $mailbox, $domain) = @_;

    # Do we have a mailbox?
    @{[$self->schema('mailbox')->check_mailbox($mailbox, $domain)->flat]} or return;
    my $deleted = $self->schema('mailbox')->delete_by_username($mailbox, $domain)->rows == 1;
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

    @{[$self->schema('vacation')->check_by_mbox($mailbox, $domain)]} and
        $self->schema('vacation')->delete_vacation($mailbox, $domain);
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
