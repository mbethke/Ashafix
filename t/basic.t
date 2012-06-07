#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Mojo::Base -strict;
use Test::More tests => 10;
use Test::Mojo;

my @credentials = (
    username => 'test@test.invalid',
    password => '12345678'
);

use_ok 'Ashafix';

my $t = Test::Mojo->new('Ashafix');
setup($t);

$t->get_ok('/')->status_is(200)->content_like(qr/Mail admins login here to administer your domain/);
$t->post_form_ok('/' => { @credentials })->status_is(302);
$t->get_ok('/main')->content_like(qr#List your aliases and mailboxes. You can edit / delete them from here.#);
$t->get_ok('/admin/list')->content_like(qr#<td><a href="/admin/edit\?username=test%40test.invalid">YES</a></td>#);

exit 0;

sub setup {
    my ($t) = @_;
    my $app = $t->app;
    # Empty all tables
    for my $model ($app->model('')->models) {
        my $m = $app->model($model);
        $m->can('delete_everything') and $m->delete_everything;
    }
    # Insert some defaults
    $app->model('admin')->raw_query(q[
        INSERT INTO %table_admin
        VALUES ('test@test.invalid','$1$J4kbnhXK$id1Eb49PlvF2hdsAAyP5G0',
        '2012-05-28 17:59:16','2012-05-28 17:59:16',1)
        ]
    );
    $app->model('domain')->raw_query(q[
        INSERT INTO %table_domain
        VALUES ('ALL','',0,0,0,0,'',0,'0000-00-00 00:00:00','0000-00-00 00:00:00', 1)
        ]
    );
    $app->model('domainadmin')->raw_query(q[
        INSERT INTO %table_domain_admins
        VALUES ('test@test.invalid','ALL','2012-05-28 17:59:16',1)
        ]
    );
}
