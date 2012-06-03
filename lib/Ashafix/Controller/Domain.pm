package Ashafix::Controller::Domain;
use Mojo::Base 'Ashafix::Controller';
use Email::Valid;
use HTML::Entities;
use Try::Tiny;

sub create {
    my $self = shift;
    my $conf = $self->stash('config');
    my %params;
    my %defaults = (
        'domain'         => [ undef ],
        'description'    => [ '' ], 
        'aliases'        => [ $conf->{aliases} ],
        'mailboxes'      => [ $conf->{mailboxes} ],
        'maxquota'       => [ $conf->{maxquota} ],
        'transport'      => [ $conf->{transport_default}, @{$conf->{transport_options}} ], 
        'defaultaliases' => [ 'off', 'on', 'off' ],
        'backupmx'       => [ 'off', 'on', 'off' ],
    );
    my %onoff = ( on => 1, off => 0 );

    while(my ($field, $def) = each %defaults) {
        my $default = shift @$def;
        my $val     = $self->param($field) // $default;
        print "Param `$field' => `$val'\n";
        $val = $default unless length $val;
        if(defined $val and @$def) {
            # Likely a hacking attempt, no need to be user friendly
            grep { $_ eq $val } @$def or die "Invalid value `$val' given for `$field'";
        }
        $params{$field} = $val;
    }

    # TODO RESTful
    'GET' eq $self->req->method and return $self->render(%params);

    my $backupmx = '';
    $self->_check_domain($params{domain}) or return $self->render(
        %params,
        pAdminCreate_domain_domain_text => $self->l('pAdminCreate_domain_domain_text_error2'),
        $self->_domain_exists($params{domain}) ?
        (pAdminCreate_domain_domain_text_error => $self->l('pAdminCreate_domain_domain_text_error')) :
        ()
    );

    # TODO handle pgsql for backupmx (db_get_boolean)
    1 == $self->model('domain')->insert(
        @params{qw/domain description aliases mailboxes maxquota transport/},
        $onoff{$params{backupmx}}
    )->rows or return $self->render(
        %params, 
        # TODO get rid of HTML crap
        message => $self->l('pAdminCreate_domain_domain_result_error') . "<br />($params{domain})<br />",
    );

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
    my ($admin_properties, $is_globaladmin, $username, @admins, @domains);

    my $model = $self->model('complex');

    if($self->auth_has_role('globaladmin')) {
        $is_globaladmin = 1;
        # Global admins can see all other admins' domains
        @admins = $self->model('admin')->get_all_admin_names->flat;
        $username = $self->param('username');
        if($username) {
            $admin_properties = $self->get_admin_properties($username);
        }
    } else {
        @admins  = $self->auth_get_username;  # only one element
    }

    if($is_globaladmin or ($admin_properties and 'ALL' eq $admin_properties->{domain_count})) {
        @domains = 'ALL';
    } elsif(defined $username and length $username) {
        @domains = $model->get_domains_for_admin($username);
    } elsif($is_globaladmin) {
        @domains = 'ALL';
    } else {
        @domains = $model->get_domains_for_admin($self->auth_get_username);
    }

    my %domain_props = map {
        # TODO map pgsql booleans to standard form
        ( $_->{domain} => $_ )
    } $model->get_domain_stats(@domains)->hashes;
    $domain_props{$_->{domain}}{alias_count} = $_->{alias_count}
        foreach $model->get_aliases_per_domain(@domains)->hashes;

    return $self->render(
        admins => \@admins,
        domainprops => \%domain_props,
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
