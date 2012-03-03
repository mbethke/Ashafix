package Ashafix;
use Mojo::Base 'Mojolicious';

use Carp;
use MojoX::Renderer::TT;
use Mojolicious::Plugin::Config;
use Ashafix::Model;
use Ashafix::Controller;
use Data::Dumper;
use Template::Constants;
use Crypt::PasswdMD5 ();
use Digest::MD5 ();

my $VERSION = '0.0.1';

sub startup {
    my $self = shift;
    $Carp::Verbose = 1;     # TODO debugging only
    $self->setup_plugins;
    $self->setup_routing;
}

sub setup_plugins {
    my $self = shift;

    # Load config
    $self->plugin(
        Config => {
            file      => 'ashafix.conf',
            stash_key => 'conf'
        }
    );

    # Helper for quick config access
    $self->helper(cfg => sub { $_[0]->stash('conf')->{$_[1]} });

    # Load Template Toolkit and set as default
    $self->plugin(
        tt_renderer => {
            template_options=> {
                #STRICT      => 1,
                #DEBUG => DEBUG_DIRS,
                #DEBUG_FORMAT => '<!-- $file line $line : [% $text %] -->',
                PRE_CHOMP   => Template::Constants::CHOMP_GREEDY,
                POST_CHOMP  => Template::Constants::CHOMP_GREEDY,
                PRE_PROCESS => [ qw/ header.tt / ],
                POST_PROCESS=> 'footer.tt',
                EVAL_PERL   => 1,
                CONSTANTS   => {
                    version => $VERSION,
                }
            }
        },
    );
    $self->renderer->default_handler('tt');

    # Set our own controller
    $self->controller_class('Ashafix::Controller');

    # Setup signed sessions
    $self->app->secret($self->app->defaults->{conf}{secret});
    #$self->sessions->cookie_domain('localhost');    # TODO configurable
    $self->sessions->cookie_name('ashafix');

    # Language support
    $self->plugin('I18N' => { default => 'en'});

    # Init the model
    $self->setup_model;

    # Extra helpers needed for the templates
    # TODO obsolete this and move into controller
    $self->helper(sprintf => sub {
            shift;  # remove $self
            my $fmt = shift;
            return sprintf($fmt, @_)
        }
    );
}

sub setup_routing {
    my $self = shift;
    my $r = $self->routes;
    $r->namespace('Ashafix::Controller'); # we want models separated

    # Authentication conditions
    $r->add_condition(login => sub { $_[1]->auth_require_login });
    $r->add_condition(role  => sub { $_[1]->auth_require_role($_[3]) });

    $r->route('/')                                       ->to('main#login')         ->name('login');
    $r->route('/logout')                                 ->to('main#logout')        ->name('logout');
    $r->route('/main')          ->over('login')          ->to('main#index')         ->name('index');
    $r->route('/mailsend')      ->over('login')          ->to('misc#sendmail')      ->name('mailsend');
    $r->route('/passwordchange')->over('login')          ->to('misc#changepassword')->name('changepassword');
    $r->route('/backup')        ->over('role' => 'admin')->to('misc#runbackup')     ->name('runbackup');
    $r->route('/logview')       ->over('role' => 'admin')->to('misc#viewlog')       ->name('viewlog');

    $self->_generic_routing(
        {
           admin => {
               list     => 'globaladmin',
               create   => 'globaladmin',
               delete   => 'globaladmin',
               edit     => 'globaladmin',
           },
           alias => {
               form     => 'GET#user',
               create   => 'POST#user',
               delete   => 'GET#user',
           },
           domain => {
               list     => 'admin',
               delete   => 'globaladmin',
               create   => 'globaladmin',
           },
           domainalias => {
               delete   => 'globaladmin',
           },
           mailbox => {
               create   => 'admin',
               delete   => 'admin',
           },
           virtual => {
               list     => 'admin',
           },
           fetchmail => {
               run      => 'user',
           },
        }
    );

    $r->route('/sendmail')->over('login')->to('misc#sendmail')->name('mail-send');
    $r->route('/password')->over('login')->to('misc#password')->name('passwd-change');
    $r->route('/viewlog') ->over('login')->to('misc#viewlog') ->name('log-view');
}

sub setup_model {
    my $self = shift;
    my $config = $self->config('database');
    my $model = Ashafix::Model->new(
        dsn         => "DBI:$config->{type}:database=$config->{name};host=$config->{host}",
        user        => $config->{user},
        password    => $config->{password},
        tabledefs   => $self->config('database_tables'),
        newquota    => $self->config('new_quota_table'),
    );
    $self->helper(model => sub { return $model->model($_[1]) });
}

# { controller => { action => role } }
sub _generic_routing {
    my ($self, $desc) = @_;
    my $r = $self->routes;

    while(my ($controller, $actions) = each %$desc) {
        while(my ($action, $m_role) = each %$actions) {
            my ($methods, $role) = split /#/, $m_role;
            my $route = $r->route("/$controller/$action")
            ->to(controller => $controller, action => $action)
            ->name("$controller-$action");
            if(defined $role) {
                $route->over('user' eq $role ? 'login' : (role => $role))
                ->via(split /\|/, $methods);
            } else {
                $route->over('user' eq $m_role ? 'login' : (role => $m_role))
            }
        }
    }
}

# Encrypt a password, using the appropriate hashing mechanism as defined in 
# mailadmin.conf ('encrypt'). 
# When wanting to compare one pw to another, it's necessary to provide the salt used - hence
# the second parameter ($pw_db), which is the existing hash from the DB.
#
# @param string $pw
# @param string $encrypted password
# @return string encrypted password.
#
sub pacrypt {
    my ($self, $pw, $pw_db) = @_;

    my $algo = $self->config('encrypt');

    if('md5crypt' eq $algo) {
        my ($salt) = defined $pw_db ? $pw_db =~ /\$1\$([^\$]+)\$/ : ();
        return Crypt::PasswdMD5::unix_md5_crypt($pw, $salt);
    }

    if('md5' eq $algo) {
        return Digest::MD5::md5_hex($pw);
    }

    if('system' eq $algo) {
        my $salt;
        if($pw_db =~ /\$1\$([^\$]+)\$/) {
            $salt = $1
        }
        else {
            if(defined $pw_db and length $pw_db >= 2) {
                $salt = substr ($pw_db, 0, 2);
            } else {
                $salt = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
            }
        }
        return crypt($pw, $salt);
    }

    return $pw if 'cleartext' eq $algo;

    # this is apparently useful for pam_mysql etc.
    if('mysql_encrypt' eq $algo) {
        my $res;
        if(defined $pw_db and length $pw_db >= 2) {
            $res = $self->model('misc')->encrypt_salted($pw, substr($pw_db, 0, 2));
        } else {
            $res = $self->model('misc')->encrypt($pw);
        }
        return scalar $res->list;
    }

    if($algo =~ /^dovecot:i(.*)/) {
        my $method = $1;
        $method =~ /^[A-Z0-9-]+$/ or die "invalid dovecot encryption method `$method'";
        'md5-crypt' eq lc $method and die "encrypt = 'dovecot:md5-crypt' will not work because dovecotpw generates a random salt each time. Please use encrypt = 'md5crypt' instead."; 

        my $dovecotpw = $self->config('dovecotpw') || 'dovecotpw';
        my $passwd = qx/$dovecotpw -p $pw/;
        chomp $passwd;
        $passwd =~ /^\{$method\}(.*)/ or die "dovecotpw failed: can't encrypt password with this method";
        return $1;
    }

    #TODO implement authlib
#    if('authlib' eq $algo) {
#    elseif ($CONF['encrypt'] == 'authlib') {
#        $flavor = $CONF['authlib_default_flavor'];
#        $salt = substr(create_salt(), 0, 2); # courier-authlib supports only two-character salts
#        if(preg_match('/^{.*}/', $pw_db)) {
#            // we have a flavor in the db -> use it instead of default flavor
#            $result = preg_split('/[{}]/', $pw_db, 3); # split at { and/or }
#            $flavor = $result[1];  
#            $salt = substr($result[2], 0, 2);
#        }
#
#        if(stripos($flavor, 'md5raw') === 0) {
#            $password = '{' . $flavor . '}' . md5($pw);
#        } elseif(stripos($flavor, 'md5') === 0) {
#            $password = '{' . $flavor . '}' . base64_encode(md5($pw, TRUE));
#        } elseif(stripos($flavor, 'crypt') === 0) {
#            $password = '{' . $flavor . '}' . crypt($pw, $salt);
#	} elseif(stripos($flavor, 'SHA') === 0) {
#	    $password = '{' . $flavor . '}' . base64_encode(sha1($pw, TRUE));
#        } else {
#            die("authlib_default_flavor '" . $flavor . "' unknown. Valid flavors are 'md5raw', 'md5', 'SHA' and 'crypt'");
#        }
#    }
    
    die "unknown/invalid encrypt setting: $algo";
}

1;
