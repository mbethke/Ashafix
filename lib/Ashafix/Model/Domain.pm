package Ashafix::Model::Domain;
#===============================================================================
#
#         FILE: Domain.pm
#
#  DESCRIPTION: Domain class
#
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/12/2012 08:30:08 AM
#===============================================================================

use Mojo::Base 'Ashafix::Model::Base'; 
use Ashafix::Result::Domain;
use Email::Valid;

my %onoff = ( on => 1, off => 0 );

sub create {
    my $self = shift;
    my %params = @_;
    my $r = Ashafix::Result::Domain->new(@_);

    $self->_check_existence($r->domain);
    $self->_check_domain_name($r->domain);

    my $backupmx = '';

    1 == $self->schema('domain')->insert(
        @params{qw/domain description aliases mailboxes maxquota transport/},
        $onoff{$params{backupmx}}
    )->rows
        or $self->throw('pAdminCreate_domain_result_error',
            # TODO is this error the same for PostgreSQL?
            # TODO localize
            (/Duplicate entry '[^']*' for key 'PRIMARY'/ ? ' Already exists' : '') .
            " (" . $r->domain . ")"
        );

    if('on' eq $params{defaultaliases}) {
        while(my ($alias, $dest) = each %{$self->cfg('default_aliases')}) {
            $self->schema('alias')->insert("$alias\@$params{domain}", $dest, $params{domain}, 1);
        }
    }

    # TODO differentiate between failure here and in the previous step
    $self->_postcreation($params{domain}) or $self->throw('pAdminCreate_domain_error');
    return $r;
}

sub load {
    my ($self, $domain) = @_;
    return Ashafix::Result::Domain->new(domain  => $domain, %{$self->_get_domain_properties($domain)});
}

sub delete {
    my ($self, $domain) = @_;
    my $rows = $self->schema('domain')->delete($domain)->rows;

    # Success if deletion succeeded and post-delete command ran OK
    unless($rows and $self->_postdeletion($domain)) {
        $self->stash(message => $self->l('pAdminDelete_domain_error'));
    }
}

# Return a hash of hashes keyed by domain name according to the list of names
# passed in; values are domain statistics
# TODO does this make sense or should it return some kind of stats objects?
sub stats {
    my $self = shift;
    my $s = $self->schema('complex');
        
    my %domain_props = map { $_->{domain} => $_ } $s->get_domain_stats(@_)->hashes;
    $domain_props{$_->{domain}}{alias_count} = $_->{alias_count}
        for $s->get_aliases_per_domain(@_)->hashes;
    return \%domain_props;
}

# Return a list of domain names for the admin name passed in, or all of them if 
# called without argument.
sub list {
    my ($self, $admin) = @_;
    defined $admin and return $self->schema('complex')->get_domains_for_admin($admin)->flat;
    return $self->schema('domain')->get_real_domains->flat;
}

sub aliases {
    my $self = shift;
    $self->schema('complex')->get_domain_stats(@_); 
}

# Check whether a domain exists in the database, dies with error if not
sub _check_existence {
    my ($self, $domain) = @_;
    my $exists = $self->schema('domain')->get_domain_props($domain)->hash;
    $self->throw('pAdminCreate_domain_domain_text_error') if $exists;
}

# Check validity of a domain name
sub _check_domain_name {
    my ($self, $domain) = @_;
    my $val = Email::Valid->new;
    my $ok = 1;

    # Check valid TLD
    $val->tld("foo\@$domain")
        or $self->throw('pInvalidDomainRegex', encode_entities($domain));

    # Check working DNS lookup
    if($self->cfg('emailcheck_resolve_domain')) {
        try {
            $val->mx($domain) or die "unresolvable";
        } catch {
            $self->throw('pInvalidDomainDNS', encode_entities($domain));
        }
    }
}

# Run postcreation script specified in config
sub _postcreation {
    my ($self, $domain) = @_;
    my $script = $self->cfg('domain_postcreation_script') or return 1;

    unless(length $domain) {
        # TODO localize
        $self->throw('', "Warning: empty domain parameter in _postcreation()");
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
        $self->throw('', "WARNING: Problems running domain postcreation script!");
        return;
    }

    return 1;
}

# Run postdeletion script specified in config
sub _postdeletion {
    my ($self, $domain) = @_;
    1;
    # TODO finish
}


1;
