package Ashafix::Controller::Domain;
use Mojo::Base 'Ashafix::Controller';
use Email::Valid;
use HTML::Entities;
use Try::Tiny;

my %onoff = ( on => 1, off => 0 );

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

    my $backupmx = '';
    $self->_check_domain($params{domain}) or return $self->render(
        %params,
        pAdminCreate_domain_domain_text => $self->l('pAdminCreate_domain_domain_text_error2'),
        $self->_domain_exists($params{domain}) ?
        (pAdminCreate_domain_domain_text_error => $self->l('pAdminCreate_domain_domain_text_error')) :
        ()
    );

    try {
        1 == $self->model('domain')->insert(
            @params{qw/domain description aliases mailboxes maxquota transport/},
            $onoff{$params{backupmx}}
        )->rows or die;
    } catch {
        return $self->render(
            %params, 
            # TODO is this error the same for PostgreSQL?
            message => $self->l('pAdminCreate_domain_result_error') . 
            # TODO localize
            (/Duplicate entry '[^']*' for key 'PRIMARY'/ ? ' Already exists' : '') .
            " ($params{domain})",
        );
    };

    if('on' eq $params{defaultaliases}) {
        while(my ($alias, $dest) = each %{$conf->{default_aliases}}) {
            $self->model('alias')->insert("$alias\@$params{domain}", $dest, $params{domain}, 1);
        }
    }

    # TODO differentiate between failure here and in the previous step
    if(!$self->_postcreation($params{domain}))
    {
         return $self->render(%params,
             message => $self->l('pAdminCreate_domain_error')
         );
    }

    # All is well
    return $self->render(%params,
        message => $self->l('pAdminCreate_domain_result_success')
    ); 
}

sub delete {
    my $self = shift;
    my $domain = $self->param('domain');

    # Delete domain in all sorts of tables (TODO use Foreign Keys and do away with this!)
    $self->model('domainadmin')->delete_by_domain($domain);
    $self->model('alias')->delete_by_domain($domain);
    $self->model('mailbox')->delete_by_domain($domain);
    $self->model('aliasdomain')->delete_by_alias($domain);
    $self->model('log')->delete($domain);
    $self->model('vacation')->delete_by_domain($domain) if $self->stash('config')->{vacation};

    # Finally delete the main entry
    my $rows = $self->model('domain')->delete($domain)->rows;

    # Success if last deletion succeeded and post-delete command ran OK
    unless($rows and $self->_postdeletion($domain)) {
        $self->stash(tMessage => $self->l('pAdminDelete_domain_error'));
    }
    return $self->redirect_to('domain-list');
}

sub list {
    my $self = shift;
    my ($admin, $is_globaladmin, $username, @admins, @domains);

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

    my $domain_props = $self->model('domain')->stats(@domains);

    return $self->render(
        admins => \@admins,
        domainprops => $domain_props,
        user => { roles => $self->session('roles') },
    ); 
}

sub _check_domain {
    my ($self, $domain) = @_;
    my $val = Email::Valid->new;
    my $ok = 1;
    # Check valid TLD
    unless($val->tld("foo\@$domain")) {
        $self->show_error(sprintf($self->l('pInvalidDomainRegex'), encode_entities($domain)));
        return;
    }
    # Check working DNS lookup
    if($self->stash('config')->{emailcheck_resolve_domain}) {
        try {
            $val->mx($domain) or die "unresolvable";
        } catch {
            $self->show_error(sprintf($self->l('pInvalidDomainDNS'), encode_entities($domain)) . ": $_");
            $ok = 0;
        }
    }
    return $ok;
}

sub _domain_exists {
    my ($self, $domain) = @_;
    return $self->model('domain')->check_domain($domain)->flat->[0];
}

sub _postcreation {
    my ($self, $domain) = @_;
    my $script = $self->stash('config')->{domain_postcreation_script} or return 1;

    unless(length $domain) {
        # TODO localize
        $self->show_error("Warning: empty domain parameter in _postcreation()");
        return;
    }

    # make sure domain contains only allowed characters and lowercase it
    $domain =~ s/[^-A-Za-z0-9]//g;
    $domain =  lc $domain;

    # Run script and check for errors
    my $output = qx/$script 2>&1 $domain/;
    if ($?)
    {
        my $ret = $? >> 8;
        #error_log("$command exited with return code $ret; output:$output");
        # TODO localize
        $self->show_error("WARNING: Problems running domain postcreation script!");
        return;
    }

    return 1;
}

sub _postdeletion {
    my ($self, $domain) = @_;
    1;
    # TODO finish
}
1;
