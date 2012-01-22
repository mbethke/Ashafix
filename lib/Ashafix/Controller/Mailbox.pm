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
use MIME::Lite;

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


sub create {
    my $self = shift;
    my ($username, $domain, $pass1, $pass2, $name, $quota, $active, $send_mail);
    my ($username_error, $password_error, $quota_error);

    my $user    = $self->auth_get_username;
    my @domains = $self->get_domains_for_user;  # TODO filter for alias domains

    my $render = sub {
        $self->render(
            template        => 'mailbox/edit',
            mode            => 'create',
            username        => $username,
            active          => $active,
            domains         => \@domains,
            act_domain      => $domain,
            username_error  => $username_error,
            password_error  => $password_error,
            quota_error     => $quota_error,
            name            => $name,
            quota           => $quota,
        );
    };

    for($self->req->method) {
        when('GET') {
            $domain = $self->req->param('domain') // $domains[0];
            unless(any { $_ eq $domain } @domains) {
                # TODO localize
                $self->show_error("Invalid domain name selected, or you tried to select a domain you are not an admin for!");
                $domain = $domains[0];
            }
            $quota = $self->_allowed_quota($domain, 0);
            # TODO check for remaining domain quota, reduce $tQuota if it is
            # lower Note: this is dependent on the domain, which means to do it
            # correct we'd have to remove the domain dropdown and hardcode the
            # domain name from ?domain=... _allowed_quota() will provide the
            # maximum allowed quota 
            # TODO WTF does that mean?
            $active = 1;
        }
        when('POST') {
            ($username, $domain, $pass1, $pass2, $name, $quota, $active, $send_mail) =
            map { $self->param($_) // '' }
            qw /username domain password password2 name quota active send_mail/;
            $username = lc $username;
            $domain   = lc $domain;
            my $username_dom = "$username\@$domain";

            unless(length $username and $self->check_domain_owner($username_dom, $domain) and $self->check_email_validity($username_dom)) {
                $username_error = $self->l('pCreate_mailbox_username_text_error1');
                print STDERR "$username_error\n";
                return $render->();
            }

            unless($self->_check_mailbox_creation($domain)) {
                # Maximum number of mailboxes reached for this domain
                $username_error = $self->l('pCreate_mailbox_username_text_error3');
                print STDERR "$username_error\n";
                return $render->();
            }

            my $pass_generated;
            if(not length $pass1 and not length $pass2 and $self->cfg('generate_password')) {
                $pass1 = $self->generate_password; 
                $pass_generated = 1;
            } elsif(not length $pass1 or not length $pass2 or $pass1 ne $pass2) {
                $password_error = $self->l('pCreate_mailbox_password_text_error');
                print STDERR "$password_error\n";
                return $render->();
            } else {
                eval { $self->validate_password($pass1) };
                if($@) {
                    # TODO localize
                    chomp $@;
                    $password_error = "Password check failed: $@";
                    print STDERR "$password_error\n";
                    return $render->();
                }
            }

            if($self->cfg('quota') and !$self->check_quota($quota, $domain)) {
                # Not enough quota for domain to accomodate the specified amount
                $quota_error = $self->l('pCreate_mailbox_quota_text_error');
                print STDERR "$quota_error\n";
                return $render->();
            }

            if(@{[$self->model('alias')->get_goto_by_address($username_dom)->flat]}) {
                # Mailbox already exists
                $username_error = $self->l('pCreate_mailbox_username_text_error2');
                print STDERR "$username_error\n";
                return $render->();
            }

            unless($username_error or $password_error or $quota_error) {
                my $maildir;
                my $password = $self->app->pacrypt($pass1);
                if($self->cfg('maildir_name_hook')) {
                    # TODO call creation hook here
                } elsif($self->cfg('domain_path')) {
                    $maildir = $self->cfg('domain_in_mailbox') ? "$domain/$username_dom/" : "$domain/$username/"
                } else {
                    $maildir = "$username_dom/";
                }

                $quota = $self->multiply_quota($quota) // 0;

                # TODO handle Postgres (0,1)=>('f','t');
                $active = 'on' eq $active ? 1 : 0;
                # TODO support Postgres' transactions (db_query('BEGIN');)

                if(1 == $self->model('alias')->insert($username_dom, $username_dom, $domain, $active)->rows) {
                    # INSERT was successful
                    if(1 == $self->model('mailbox')->insert($username_dom, $password, $name, $maildir, $username, $quota, $domain, $active)->rows) {
                        # TODO db_query('COMMIT');
                        $self->db_log($domain, 'create_mailbox', $username_dom);
                        $quota = $self->_allowed_quota($domain, 0);
                        $self->_welcome_mail($username_dom) if $send_mail eq 'on';

                        my $showpass = ($pass_generated or $self->cfg('show_password')) ? " / $password" : '';
                        my $folders_ok = $self->_create_mailbox_subfolders($username_dom, $password);
                        $self->show_info($self->l(
                                $folders_ok ?
                                'pCreate_mailbox_result_success' :
                                'pCreate_mailbox_result_succes_nosubfolders') .
                            "<br />($username$showpass)"
                        );
                    } else {
                        # TODO should we try to manually roll back the previous INSERT for MySQL?
                        # TODO db_query('ROLLBACK');
                        $self->show_error($self->l('pCreate_mailbox_result_error') . "<br />($username_dom)");
                        return $render->();
                    }

                } else {
                    # TODO get rid of HTML here
                    $self->show_error($self->l('pAlias_result_error') . "<br />($username_dom -> $username_dom)");
                    # TODO db_query('ROLLBACK');
                    return $render->();
                }

            }
        }
    }
    return $render->();
}

sub _welcome_mail {
    my ($self, $to) = @_;

    my $msg = MIME::Lite->new(
        From    => $self->cfg('admin_email') || $self->auth_get_username,
        To      => $to,
        Subject => $self->l('pSendmail_subject_text'),
        Type    => 'text/plain',
        Data    => $self->cfg('welcome_text'), 
    );
    eval {
        $msg->send('smtp', $self->cfg('smtp_server') || 'localhost',
            Port    => $self->cfg('smtp_port') || 25,
            Timeout => 30,
        );
    };
    if($@) {
        chomp $@;
        $self->show_error($self->l('pSendmail_result_error') . "($@)");
    } else {
        $self->show_info($self->l('pSendmail_result_success'));
    }
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
    print STDERR "TODO: Controller::Mailbox::_mailbox_postdeletion\n";
}

1;
