package Ashafix::Controller::Main;
use Mojo::Base 'Ashafix::Controller';
use Ashafix::I18N;
use Data::Dumper;

sub index {
    my $self = shift;
    # just render
}

sub login {
    my $self = shift;
    my $name = $self->param('fUsername');
    my $pass = $self->param('fPassword');
    my $lang = $self->param('lang');

    return $self->render(
        # TODO generate from modules in I18N::* ? What about localized language names?
        supported_languages => Ashafix::I18N::supported_languages
    ) unless defined $name and defined $pass;

    my $stored_pass = $self->_find_password($name);
    if(defined $stored_pass and
        $self->app->pacrypt($pass, $stored_pass) eq $stored_pass)
    {
        # Login successful
        # TODO how to check for admin vs. user?
        $self->session('user', { name => $name, roles => { 'admin' => 1 }});
        # Check for global admin
        $self->session('user')->{roles}{globaladmin} = $self->_check_global_admin;
        $self->redirect_to('index');
    } else {
        # Login failed
        $self->show_error($self->l('pLogin_failed'));
    }
}

sub logout {
    my $self = shift;
    $self->session(expires => 1); # invalidate
    $self->redirect_to('index');
};

sub _find_password {
    my ($self, $user) = @_;
    my $pass = $self->model('admin')->get_password($user)->list;
    return $pass if defined $pass;
    return $self->model('mailbox')->get_password($user)->list;
}

sub _check_global_admin { defined $self->model('domainadmin')->check_global_admin($name)->list }

1;
