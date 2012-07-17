package Ashafix::Controller::Admin;
use Mojo::Base 'Ashafix::Controller';
use Email::Valid;
use Digest::MD5;
use Try::Tiny;

sub create {
    my $self = shift;
    my $m = $self->model('admin');
    my @render_params = (
        pAdminCreate_admin_username_text => $self->l('pAdminCreate_admin_username_text'),
        domains                          => [ $self->schema('domain')->get_real_domains->flat ],
    );

    for($self->req->method) {
        when('GET') {
        }
        when('POST') {
            my $bp = $self->req->body_params;
            try {
                my $admin = $m->create(
                    name    => $bp->param('username'),
                    pw1     => $bp->param('password'),
                    pw2     => $bp->param('password2'),
                    domains => [ split / /, ($bp->param('domains') // '') ],
                );
                $self->show_info_l('pAdminCreate_admin_result_success');
            } catch {
                warn "Caught exception in Ashafix::Controller::Admin::create: $_";
                my $msg = $self->handle_exception($_);
                warn "MSG: `$msg'";
                $self->show_error($self->handle_exception($_));
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

    try {
        $self->model('admin')->delete($self->param('username')) or die;
    } catch {
        return $self->render(
            # TODO translate this message from English
            message => $self->l('pAdminDelete_admin_error'),
        );
    };
    return $self->redirect_to('admin-list');
}

sub list {
    my $self = shift;
    my $m = $self->model('admin');

    return $self->render(
        admins => {
            map { $_ => $m->load($_) } $self->model('admin')->list
        }
    ); 
}

sub edit {
    my ($self) = @_;
    die "Unimplemented";
}

1;

