package Ashafix::Controller::Domain;
use Mojo::Base 'Ashafix::Controller';
use HTML::Entities;
use Try::Tiny;

sub create {
    my $self = shift;
    my $conf = $self->stash('config');
    my %params;
    my %defaults = (
        'domain'         => undef,
        'description'    => '', 
        'aliases'        => $conf->{aliases},
        'mailboxes'      => $conf->{mailboxes},
        'maxquota'       => $conf->{maxquota},
        'transport'      => $conf->{transport_default},
        'defaultaliases' => 'off',
        'backupmx'       => 'off',
    );
    my %permissible = (
        'transport'      => [ @{$conf->{transport_options}} ], 
        'defaultaliases' => [ 'on', 'off' ],
        'backupmx'       => [ 'on', 'off' ],
    );

    # Validate parameters
    # TODO factor out to Ashafix::Controller?
    while(my ($field, $def) = each %defaults) {
        my $val = $self->param($field) // $defaults{$field};
        $val = $defaults{$field} unless length $val;
        if(defined $val and exists $permissible{$field}) {
            # Likely a hacking attempt, no need to be user friendly
            grep { $_ eq $val } @{$permissible{$field}} or
            die "Invalid value `$val' given for `$field'";
        }
        $params{$field} = $val;
    }

    # TODO RESTful
    $self->req->method =~ /^(?:GET|HEAD)/ and return $self->render(%params);

    try {
        $self->model('domain')->create(%params);
        $self->show_info_l('pAdminCreate_domain_result_success');
    } catch {
        $self->show_error($self->handle_exception($_));
    };
    return $self->render(%params);
}

sub delete {
    my $self = shift;
    $self->model('domain')->delete($self->param('domain'));
    return $self->redirect_to('domain-list');
}

sub list {
    my $self = shift;
    my ($admin, $is_globaladmin, $username, @admins, @domains);
    my $domain_props = [];

    try {
        if($self->auth_has_role('globaladmin')) {
            $is_globaladmin = 1;
            # Global admins can see all other admins' domains
            @admins = $self->model('admin')->list;
            $username = $self->param('username')
                and $admin = $self->model('admin')->load($username);
        } else {
            @admins = $self->auth_get_username;  # only one element
        }

        # TODO is the "or" clause needed?
        if($is_globaladmin or ($admin and 'ALL' eq $admin->domain_count)) {
            @domains = 'ALL';
        } elsif(defined $username and length $username) {
            @domains = @{$admin->domains};
        } elsif($is_globaladmin) {
            @domains = 'ALL';
        } else {
            @domains = @{$self->model('admin')->load($self->auth_get_username)->domains};
        }

        $domain_props = $self->model('domain')->stats(@domains);
    } catch {
        $self->show_error($self->handle_exception($_));
    };

    return $self->render(
        admins => \@admins,
        domainprops => $domain_props,
        user => { roles => $self->session('roles') },
    ); 
}

1;
