package Ashafix::Controller::Mailbox;
use Mojo::Base 'Ashafix::Controller';

sub create {
    my $self = shift;
    my $user = $self->auth_get_username;
    my @domains = $self->auth_has_role('globaladmin') ? 
}

1;
