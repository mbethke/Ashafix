package Ashafix::Controller::Alias;
#===============================================================================
#
#         FILE:  Alias.pm
#
#  DESCRIPTION:  Alias controller
#
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  10/17/2011 02:41:11 AM
#     REVISION:  ---
#===============================================================================

use 5.010;
use Mojo::Base 'Ashafix::Controller::MailAddress';
use List::MoreUtils qw/ any uniq /;
use Try::Tiny;

sub form {
    my $self = shift;
    my $domain = $self->param('domain') // '';
    return $self->_render_create(domain => $domain);
}

sub create {
    my $self = shift;
    my $user  = $self->auth_get_username;
    my $model = $self->model('alias');

    die "Check ashafix.conf - domain administrators do not have the ability to edit user's aliases (alias_control_admin)" # TODO do this more user friendly
        unless($self->cfg('alias_control_admin') or $self->auth_has_role('globaladmin'));

    # Get parameters and check that values are given
    my ($address, $domain, $goto, $active) = map { $self->param($_) } qw/ address domain goto active /;
    die "Required parameter missing" if any { !length } ($domain, $address, $goto);   # TODO user-friendly

    # Check that logged user owns domain and alias address is valid
    return $self->_render_create_error($domain, $address, $goto, 'pCreate_alias_address_text_error1')
        unless($self->check_domain_owner($user, $domain) and
            $self->check_email_validity("$address\@$domain"));

    # Check that further alias creation is allowed for this domain
    return $self->_render_create_error($domain, $address, $goto, 'pCreate_alias_address_text_error3')
        unless $self->_alias_creation_allowed($domain);

    # Convert forward destination addresses to list
    my $fwd = $goto;
    $fwd =~ s/\r\n/,/g;
    $fwd =~ s/\s+|^,|,$//g;
    $fwd =~ s/,{2,}/,/g; 
    my @gotos = uniq split /,/, $fwd;

    # Check that destinations are valid
    foreach(@gotos) {
        unless($self->check_email_validity($_)) {
            $self->show_error($self->l('pInvalidMailRegex') . ": $_");
            return $self->_render_create_error(
                $domain, $address, $goto, 'pCreate_alias_address_text_error1'
            );
        }
    }
    $goto = join ",", @gotos;

    # Handle special case of catch-all alias
    $address = "\@$domain" if '*' eq $address;

    # Check whether alias exists already
    my @res = $model->get_by_address($address, $domain)->hashes;
    return $self->_render_create_error($domain, $address, $goto, 'pCreate_alias_address_text_error2')
        if @res;

    $active = lc $active eq 'on';  # TODO handle postgres

    my $fromto_text = "$address -> $goto";

    # TODO check $goto for catchalls as well? PFA does it, I think it's bull
    my $success = try {
        1 == $model->insert("$address\@$domain", $domain, $goto, $active)->rows;
    };
    if($success) {
        $self->db_log($domain, 'create_alias', $fromto_text);
        $self->show_info($self->l('pCreate_alias_result_success') . "<br />($fromto_text)<br />");
        $address = '';  # delete for next form
        @gotos = ();
    } else {
        # Alias creation failed
        $self->show_error($self->l('pCreate_alias_result_error') . "<br />($fromto_text)<br />");
        warn "alias creation failed ($fromto_text)";
    };
    return $self->_render_create(
        domain      => $domain,
        address     => $address,
        goto        => join("\r\n", @gotos),
    );
}

sub delete {
    my $self = shift;
    die "unimplemented";
}

sub _alias_creation_allowed {
    my ($self, $domain) = @_;
    my $dprops = $self->get_domain_properties($domain);
    
    return 1 unless $dprops->{aliases}; # 0 = unlimited no. of aliases
    return if 0 > $dprops->{aliases};   # -1 = no aliases
    return $dprops->{alias_count} < $dprops->{aliases};
}

sub _render_create {
    my $self = shift;
    return $self->render(
        template    => 'alias/edit',
        mode        => 'create',
        formto      => 'alias-create',  # TODO necessary?
        domains     => [ $self->get_domains_for_user ],
        @_
    );
}

sub _render_create_error {
    my ($self, $dom, $addr, $goto, $err) = @_;
    return $self->_render_create(
        domain      => $dom,
        address     => $addr,
        goto        => $goto,
        alias_error => $self->l($err),
    );
}

1;

