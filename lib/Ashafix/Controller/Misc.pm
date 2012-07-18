package Ashafix::Controller::Misc;
use Mojo::Base 'Ashafix::Controller';
use Try::Tiny;

sub send_mail {
    my $self = shift;
    die "unimplemented";
}

sub chpassword {
    my $self = shift;
    my $username = $self->session('user')->name;
    $self->req->method =~ /^(?:GET|HEAD)/ and return $self->render(username => $username);

    # POSTing new values
    my ($pw_old, $pw_new, $pw_new2) = map { $self->param($_) } qw / currentpw newpw newpw2 /;
    my $user = $self->verify_account($username, $pw_old) or return $self->render(
        username              => $username,
        password_current_text => $self->l('pPassword_password_current_text_error'),
    );

    if(!length($pw_new) || $pw_new ne $pw_new2) {
        return $self->render(
            username          => $username,
            password_new_text => $self->l('pPassword_password_text_error'),
        );
    }

    $user->password($self->app->pacrypt($pw_new));
    try {
        $self->update_user($user);
        $self->show_info_l('pPassword_result_success');
    } catch {
        $self->show_error_l('pPassword_result_error');
    };
    return $self->render(username => $username);
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
