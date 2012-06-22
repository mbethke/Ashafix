package Ashafix::Model::Admin;
#===============================================================================
#
#         FILE: Admin.pm
#
#  DESCRIPTION: Admin user class
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY: Zonarix S.A.
#      VERSION: 1.0
#      CREATED: 06/12/2012 12:03:09 AM
#     REVISION: ---
#===============================================================================
use Mojo::Base 'Ashafix::Model::Base';
use Mojo::Exception;
use Scalar::Util qw/ blessed /;
use Try::Tiny;
use Ashafix::Result::Admin;

# Create a new admin user
sub create {
    my $self = shift;
    my %opts = @_; # we still need to look at parameters that don't correspond to attributes
    my $r = Ashafix::Result::Admin->new(@_);
    my $name = $r->name;

    (!defined $name or '' eq $name
            or defined $self->schema('admin')->select_admin($name)->flat->[0])
        and Mojo::Exception->throw($self->l('pAdminCreate_admin_username_text_error2'));
    $self->_check_email_validity($name)
        or Mojo::Exception->throw($self->l('pAdminCreate_admin_username_text_error1'));

    my $passwd  = $self->check_passwords($opts{pw1}, $opts{pw2});
    $r->password($self->pacrypt($passwd));
    
    # Determine admin's roles---'admin' is for granted
    $r->roles({ admin => 1 });
    $r->roles->{globaladmin} = 1 if grep { $_ eq 'ALL' } @{$r->domains};

    try {
        1 == $self->schema('admin')->insert_admin($name, $r->password)->rows or die;
        foreach my $dom (@{$self->domains}) {
            # TODO error checking?
            $self->schema('domainadmin')->insert_domadmin($name, $dom);
        }
    } catch {
        # TODO localize
        $self->throw('Could not create admin!');
    };
    return $r;
}

sub load {
    my ($self, $name) = @_;
    my $r = Ashafix::Result::Admin->new(@_);

    $r->name($name);
    $r->roles({ admin => 1 });
    if(defined $self->schema('domainadmin')->select_global_admin($name)->list) {
        $r->roles->{globaladmin} = 1;
        $r->domain_count('ALL'); # TODO is this still necessary?
    } else {
        $r->domain_count( 
            scalar $self->schema('domainadmin')->select_domain_count($name)->list
        );
    };
    
    if(my $row = $self->schema('admin')->select_admin($name)->hash) {
        $r->$_($row->{$_}) foreach(qw/created modified active password/);
    }
    $r->domains([ map { $_->{domain} } $self->schema('domainadmin')->select_by_admin($name) ]);
    return $r;
}

# Delete an admin, either by name or Ashafix::Result::Admin object. Throws an
# exception if the name/object is not valid.
# Returns a positive value (should be 1) on success
sub delete {
    my ($self, $who) = @_;
    blessed($who) and $who->isa('Ashafix::Result::Admin') and $who = $who->name;
    $self->check_email_validity($who)
        or $self->throwl('pAdminDelete_admin_error');
    # Deletion of dependent domains is taken care of by the database
    return $self->schema('admin')->delete($who)->rows;
}

# Return a list of admin names
sub list { shift->schema('admin')->get_all_admin_names->flat }

# Check that passwords entered are identical; in case they're empty and config
# allows it, auto-generate one. Returns valid password on success, otherwise
# dies with error messages
sub _check_passwords {
    my ($self, $pw1, $pw2) = @_;
    
    # TODO check for undef? Should only happen by programmer error
    # Check for empty or non-matching passwords
    if('' eq $pw1 or '' eq $pw2 or $pw1 ne $pw2) {
        if('' eq $pw1 and '' eq $pw2 and $self->app->cfg('generate_password')) {
            return $self->generate_password;
        } else {
           $self->throwl('pAdminCreate_admin_username_text');
        }
    }
    return $pw1;
}

1;

