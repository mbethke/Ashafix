package Ashafix::Controller::Domainalias;
use Mojo::Base 'Ashafix::Controller';

sub delete {
    my $self = shift;

    $self->model('aliasdomain')->delete_by_alias($self->param('domain'))->rows and
    return $self->redirect_to('domainalias-list');

    # TODO error message missing
    return $self->render(template => 'message');
}

1;
