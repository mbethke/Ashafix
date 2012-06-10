package Ashafix::Controller::Misc;
use Mojo::Base 'Ashafix::Controller';

sub send_mail {
    my $self = shift;
    die "unimplemented";
}

sub chpassword {
    my $self = shift;
    my $user = $self->session('user')->{name};
    $self->req->method =~ /^(?:GET|HEAD)/ and return $self->render(username => $user);

    # POSTing new values
    my ($pw_old, $pw_new, $pw_new2) = map { $self->param($_) } qw / currentpw newpw newpw2 /;
    my $uinfo = $self->verify_account($user, $pw_old) or return $self->render(
        username              => $user,
        password_current_text => $self->l('pPassword_password_current_text_error'),
    );

    !length($pw_new) || $pw_new ne $pw_new2 and return $self->render(
        username          => $user,
        password_new_text => $self->l('pPassword_password_text_error'),
    );

    my $model_name = $self->session('user')->{roles}{admin} ? 'admin' : 'mailbox';
    if($self->model($model_name)->update_password($self->app->pacrypt($pw_new), $user)->rows) {
        $self->show_info_l('pPassword_result_success');
    } else {
        $self->show_error_l('pPassword_result_error');
    }
    return $self->render(username => $user);
}

sub view_log {
    my $self = shift;
    die "unimplemented";
}

sub run_backup {
    my $self = shift;
    die "unimplemented";
}

1;
