package Ashafix::Controller::Main;
use Mojo::Base 'Ashafix::Controller';
use Ashafix::I18N;
use Data::Dumper;

sub index {
    # just render
}

sub login {
    my $self    = shift;
    my $name    = $self->param('username');
    my $pass    = $self->param('password');
    my $redir   = $self->param('redirect');

    return $self->render unless defined $name and defined $pass;

    my $user = $self->verify_account($name, $pass);
    if($user) {
        # Login successful
        $self->session('user', $user);
        $self->redirect_to($redir || 'index');
    } else {
        # Login failed
        $self->show_error_l('pLogin_failed');
    }
}

sub logout {
    my $self = shift;
    $self->session(expires => 1); # invalidate
    $self->redirect_to('index');
};

sub _find_password {
    my ($self, $user) = @_;
    return unless defined $user;
    my $pass = $self->model('admin')->get_password($user)->list;
    return $pass if defined $pass;
    return $self->model('mailbox')->get_password($user)->list;
}

1;
