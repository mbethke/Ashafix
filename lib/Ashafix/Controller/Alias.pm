package Ashafix::Controller::Alias;
use Mojo::Base 'Ashafix::Controller::MailAddress';
use 5.010;

sub new {
    my $self = shift;
    my $domain = $self->param('domain') // '';
    return $self->render(
        template    => 'alias/edit'
        mode        => 'create',
        domain      => $domain
    );
}

sub create {
    my $self = shift;
    my $user    = $self->auth_get_username;
    !$self->cfg('alias_control_admin') and !$self->auth_has_role('globaladmin') and
        die "Check ashafix.conf - domain administrators do not have the ability to edit user's aliases (alias_control_admin)"; # TODO do this more user friendly
    my $address  = $self->param('address');
    my ($domain) = $address =~ /\@(.*)/;
    die "Required parameters not present" unless length $domain;
    my $res = $self->model('alias')->get_by_address($address, $domain)->hash;

}

sub delete {
    my $self = shift;
    die "unimplemented";
}

1;

