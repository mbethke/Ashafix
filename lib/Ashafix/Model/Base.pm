package Ashafix::Model::Base;
#===============================================================================
#
#         FILE:  Base.pm
#
#  DESCRIPTION:  Base class for individuial tables or abstractions
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/12/2011 11:06:55 AM
#     REVISION:  ---
#===============================================================================
use strict;
use warnings;

sub new {
    my ($class, $config) = @_;
    my $tabledefs = $config->{tabledefs};

    # Install a new method for each member of the package-global %queries
    no strict 'refs';
    while(my ($name, $sql) = each %{"${class}::queries"}) {
        $sql = _edit_sql($sql, $tabledefs);
        *{"${class}::$name"} = sub { shift; return Ashafix::Model::query($sql, @_) };
    }
    
    # Just replace table names in package-global %snippets
    $_ = _edit_sql($_, $tabledefs) foreach(values %{"${class}::snippets"});

    return bless [], $class;
}

# Returns SQL for an IN-clause using bind parameters:
# IN(?,?,...) with one parameter for each element of the argument array
# minus the implied $self (this is a method!)
sub sql_in_clause_bindparams {
    return ' IN (' . join(',', ('?') x (@_ - 1)) . ') ';
}

# Not a method!
sub _edit_sql {
    local $_ = $_[0];
    s/%table_(\w+)/$_[1]->{$1}/eg;
    s/\n//g;
    s/\s\s*/ /g;
    return $_;
}

1;
