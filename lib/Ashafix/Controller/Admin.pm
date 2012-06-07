package Ashafix::Controller::Admin;
use feature qw/switch/;
use Mojo::Base 'Ashafix::Controller';
use Email::Valid;
use Digest::MD5;
use Try::Tiny;

sub create {
    my $self = shift;
    my @render_params = (
        pAdminCreate_admin_username_text => $self->l('pAdminCreate_admin_username_text'),
        domains                          => [ $self->model('domain')->get_real_domains->flat ],
    );

    for($self->req->method) {
        when('GET') {
        }
        when('POST') {
            my $bp = $self->req->body_params;
            try {
                my $msg = $self->_create_admin(
                    (map { $bp->param($_) } qw/username password password2/),
                    0,
                    split / /, ($bp->param('domains') // '')
                );
                $self->show_info($msg);
            } catch {
                warn "Exception while trying to create admin";
                $self->show_error($_) for(@$_);
            };
        }
        default {
            die "Can only GET/POST here";
        }
    }
    return $self->render(@render_params);
}

sub delete {
    my $self = shift;

    my $rows_a = $self->model('admin')->delete($self->param('username'))->rows;
    my $rows_da= $self->model('domainadmin')->delete_by_user($self->param('username'))->rows;
    
    return $self->redirect_to('admin-list') if(1 == $rows_a and 0 <= $rows_da);

    return $self->render(
        template => 'message',
        # TODO translate this message from English
        message => $self->l('pAdminDelete_admin_error'),
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

sub edit {
    my ($self) = @_;
    die "Unimplemented";
}

sub _create_admin {
    my ($self, $uname, $pw1, $pw2, $no_genpw, @domains) = @_;
    warn "uname=$uname, pw1=$pw1, pw2=$pw2, domains='@domains'";

    # Check empty address or existing admin
    if('' eq $uname or defined $self->_admin_exists($uname)) {
        warn "EXISTS: ",$self->model('admin')->select_admin($uname)->flat;
        die [ $self->l('pAdminCreate_admin_username_text_error2') ];
    }
    
    $self->_check_email_validity($uname);
    $pw1 = $self->_check_passwords($pw1, $pw2, $no_genpw);

    my $password = $self->app->pacrypt($pw1);
    if(1 == $self->model('admin')->insert_admin($uname, $password)->rows) {
        foreach my $dom (@domains) {
            # TODO error checking?
            $self->model('domainadmin')->insert_domadmin($uname, $dom);
        }
        my $message = $self->l('pAdminCreate_admin_result_success') . " ($uname";
        if($self->cfg('generate_password') or $self->cfg('show_password')) {
            $message .= " / $password";
        }
        return $message;
    }
    return;
}

sub _check_email_validity {
    my ($self, $uname) = @_;

    $self->check_email_validity($uname) or
    die [ $self->l('pAdminCreate_admin_username_text_error1') ];
}

sub _check_passwords {
    my ($self, $pw1, $pw2, $no_genpw) = @_;

    # Check for empty or non-matching passwords
    if('' eq $pw1 or '' eq $pw2 or $pw1 ne $pw2) {
        if('' eq $pw1 and '' eq $pw2 and $self->cfg('generate_password') and !$no_genpw) {
            return $self->generate_password;
        } else {
            die [
                $self->l('pAdminCreate_admin_username_text'),
                $self->l('pAdminCreate_admin_password_text_error')
            ];
        }
    }
    return $pw1;
}

sub _admin_exists {
    my ($self, $name) = @_;
    warn "_admin_exists($name): ", join ", ", $self->model('admin')->select_admin($name)->flat;
    return $self->model('admin')->select_admin($name)->flat->[0];
}
1;

