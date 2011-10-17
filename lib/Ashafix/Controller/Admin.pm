package Ashafix::Controller::Admin;
use feature qw/switch/;
use Mojo::Base 'Ashafix::Controller';
use Email::Valid;
use Digest::MD5;

sub create {
    my $self = shift;

    given($self->req->method) {
        when('GET') {
            return $self->render(
                pAdminCreate_admin_username_text => $self->l('pAdminCreate_admin_username_text'),
                tDomains => [],
                domains  => [ $self->model('domain')->get_real_domains->flat ],
            );
        }
        when('POST') {
            my $res = $self->_create_admin(
                (map { $self->param($_) } qw/fUsername fPassword fPassword2/),
                0,
                split / /, ($self->param('fDomains') // '')
            ) or return;

        }
        default {
            die "Can only GET/POST here";
        }
    }
}

sub delete {
    my $self = shift;

    my $rows_a = $self->model('admin')->delete($self->param('username'))->rows;
    my $rows_da= $self->model('domainadmin')->delete_by_user($self->param('username'))->rows;
    
    return $self->redirect_to('admin-list') if(1 == $rows_a and 0 <= $rows_da);

    return $self->render(
        template => 'message',
        # TODO translate this message from English
        tMessage => $self->l('pAdminDelete_admin_error'),
    );
}

sub list {
    my $self = shift;
    my $m = $self->model('admin');

    return $self->render(
        admins => {
            map {
            ( $_ => $self->get_admin_properties($_) )
            } $self->model('admin')->get_all_admin_names->flat
        }
    ); 
}

sub _create_admin {
    my ($self, $uname, $pw1, $pw2, $no_genpw, @domains) = @_;
    say "uname=$uname, pw1=$pw1, pw2=$pw2, domains='@domains'";

    # Check empty address or existing admin
    if('' eq $uname or defined $self->_admin_exists($uname)) {
        say "EXISTS: ",$self->model('admin')->select_admin($uname)->flat;
        $self->render(
            pAdminCreate_admin_username_text => $self->l('pAdminCreate_admin_username_text_error2')
        );
        return;
    }
    
    return unless $self->_check_email_validity($uname);
    return unless $pw1 = $self->_check_passwords($pw1, $pw2, $no_genpw);

    my $password = $self->app->pacrypt($pw1);
    if(1 == $self->model('admin')->insert_admin($uname, $password)->rows) {
        foreach my $dom (@domains) {
            # TODO error checking?
            $self->model('domainadmins')->insert_domadmin($uname, $dom);
        }
        my $message = $self->l('pAdminCreate_admin_result_success') . "<br />($uname";
        if($self->cfg('generate_password') or $self->cfg('show_password')) {
            $message .= " / $password";
        }
        $message .= ')<br />';
        $self->render(tMessage => $message);
    } else {
        # Error inserting admin record
        $self->render(
            tMessage => $self->l('pAdminCreate_admin_result_error') . "<br />($uname)<br />"
        );
    }
    return;
}

sub _check_email_validity {
    my ($self, $uname) = @_;

    my $mvalid = Email::Valid->new(
        -mxcheck => $self->cfg('emailcheck_resolve_domain'),
        -tldcheck => 1
    );
    return 1 if $mvalid->address($uname);

    my $err;
    given($mvalid->details) {
        when('fqdn')    { $err = 'pInvalidDomainRegex' }
        when('mxcheck') { $err = 'pInvalidDomainDNS'   }
        default         { $err = 'pInvalidMailRegex'   }
    }
    $self->flash(error => $self->l($err));
    $self->render(
        pAdminCreate_admin_username_text => $self->l('pAdminCreate_admin_username_text_error1')
    );
    return;
}

sub _check_passwords {
    my ($self, $pw1, $pw2, $no_genpw) = @_;

    # Check for empty or non-matching passwords
    if('' eq $pw1 or '' eq $pw2 or $pw1 ne $pw2) {
        if('' eq $pw1 and '' eq $pw2 and $self->cfg('generate_password') and !$no_genpw) {
            return $self->generate_password;
        } else {
            $self->render(
                pAdminCreate_admin_username_text => $self->l('pAdminCreate_admin_username_text'),
                pAdminCreate_admin_password_text => $self->l('pAdminCreate_admin_password_text_error')
            );
            return;
        }
    }
    return $pw1;
}

sub _admin_exists {
    my ($self, $name) = @_;
    say "_admin_exists($name): ", join ", ", $self->model('admin')->select_admin($name)->flat;
    return ($self->model('admin')->select_admin($name)->flat)[0];
}
1;

