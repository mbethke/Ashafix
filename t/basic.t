#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojo::Base -strict;
use Test::More tests => 20;
use Test::Mojo;

my @credentials = (
    username => 'test@test.invalid',
    password => '12345678'
);

use_ok 'Ashafix';

my $t = Test::Mojo->new('Ashafix');
setup($t);

# Login
$t->get_ok('/')->status_is(200)->content_like(qr/Mail admins login here to administer your domain/);
$t->post_form_ok('/' => { @credentials })->status_is(302);
# Main menu
$t->get_ok('/main')->content_like(qr#List your aliases and mailboxes. You can edit / delete them from here.#);

# Admin: list
$t->get_ok('/admin/list')->content_like(qr#<td><a href="/admin/edit\?username=test%40test.invalid">YES</a></td>#);

# Domain: list
$t->get_ok('/domain/list')->content_like(qr#<p><a href="/domain/create">New Domain</a>#);
# Domain: form
$t->get_ok('/domain/create')->content_like(qr#<td colspan="3"><h3>Add a new domain</h3></td>#);
# Domain: create
$t->post_form_ok('/domain/create' => {
        domain          => 'invalid.com',
        description     => 'Test domain',
        aliases         => 123,
        mailboxes       => 456,
        defaultaliases  => 'on'
    })->status_is(200);

# Password: form
$t->get_ok('/password')->content_like(qr#<h3>Change your login password.</h3>#);
$t->post_form_ok('/password' => {
        currentpw   => '12345678',
        newpw       => '1234567890',
        newpw2       => '1234567890',
    })->content_like(qr#<ul class="flash-info"><li>Your password has been changed!</li></ul>#);

exit 0;

sub setup {
    my ($t) = @_;
    my $app = $t->app;
    # Empty all tables
    for my $schema ($app->schema('')->schemas) {
        my $m = $app->schema($schema);
        $m->can('delete_everything') and $m->delete_everything;
    }
    # Insert some defaults
    $app->schema('admin')->raw_query(q[
        INSERT INTO %table_admin
        VALUES ('test@test.invalid','$1$J4kbnhXK$id1Eb49PlvF2hdsAAyP5G0',
        '2012-05-28 17:59:16','2012-05-28 17:59:16',1)
        ]
    );
    $app->schema('domain')->raw_query(q[
        INSERT INTO %table_domain
        VALUES ('ALL','',0,0,0,0,'',0,'0000-00-00 00:00:00','0000-00-00 00:00:00', 1),
               ('test.com','No description',0,0,0,0,'',0,'0000-00-00 00:00:00','0000-00-00 00:00:00', 1)
        ]
    );
    $app->schema('domainadmin')->raw_query(q[
        INSERT INTO %table_domain_admins
        VALUES ('test@test.invalid','ALL','2012-05-28 17:59:16',1)
        ]
    );
}
