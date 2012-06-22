package Mojolicious::Plugin::FrozenSessions;
#===============================================================================
#
#         FILE: FrozenSessions.pm
#
#  DESCRIPTION: A Mojolicious session plugin that uses FreezeThaw. Mostly copied
#               from Mojolicious::Sessions
#
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/19/2012 09:26:55 AM
#===============================================================================
use Mojo::Base 'Mojolicious::Plugin';

sub register {
    my ($self, $app, $args) = @_;
    $args ||= {};

    my $stash_key = delete $args->{stash_key} || 'mojox-frozen-session';

    $app->hook(
        before_dispatch => sub {
            my $c = shift;
            my $session = MojoX::Session::FreezeThaw->new;
            $session->load($c);
            $c->stash($stash_key => $session);
        }
    );

    $app->hook(
        after_dispatch => sub {
            my $c = shift;
            # For some reason, exceptions seem to be silently caught in this hook. Work around.
            eval { $c->stash($stash_key)->store($c) };
            if($@) { print STDERR "Exception: $@\n" }
        }
    );
}

package MojoX::Session::FreezeThaw;
use Mojo::Base -base;
use FreezeThaw qw//;
use Mojo::Util qw/ b64_decode b64_encode /;
use Data::Dumper;
has [qw/ cookie_domain secure /];
has cookie_name        => 'mojolicious';
has cookie_path        => '/';
has default_expiration => 3600;

sub load {
    my ($self, $c) = @_;

    # Get session cookie from controller
    return unless my $value = $c->signed_cookie($self->cookie_name);

    # Deserialize
    $value =~ s/-/=/g;
    return unless my ($session) = FreezeThaw::thaw(b64_decode $value);

    # Check expiration and refuse to load expired data if
    my $expiration = $self->default_expiration;
    return if !(my $expires = delete $session->{expires}) && $expiration;
    return if defined $expires && $expires <= time;

    # Content
    my $stash = $c->stash;
    return unless $stash->{'mojo.active_session'} = keys %$session;
    $stash->{'mojo.session'} = $session;

    # Flash
    $session->{flash} = delete $session->{new_flash} if $session->{new_flash};
    return $c;
}

sub store {
    my ($self, $c) = @_;

    # Check whether there is a valid session active
    my $stash = $c->stash;
    return unless my $session = $stash->{'mojo.session'};
    return unless keys %$session || $stash->{'mojo.active_session'};

    # Change old Flash to new one
    my $old = delete $session->{flash};
    @{$session->{new_flash}}{keys %$old} = values %$old
    if $stash->{'mojo.static'};
    delete $session->{new_flash} unless keys %{$session->{new_flash}};

    # Expiration
    my $expiration = $self->default_expiration;
    my $default    = delete $session->{expires};
    $session->{expires} = $default || time + $expiration
    if $expiration || $default;
    # Serialize
    my $value = b64_encode(FreezeThaw::freeze($session), '');
    $value =~ s/=/-/g;

    # Pass session cookie to controller for HMACing
    $c->signed_cookie($self->cookie_name, $value, {
            domain   => $self->cookie_domain,
            expires  => $session->{expires},
            httponly => 1,
            path     => $self->cookie_path,
            secure   => $self->secure
        }
    );
}

1;
