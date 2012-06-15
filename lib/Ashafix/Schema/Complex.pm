package Ashafix::Schema::Complex;
#===============================================================================
#
#         FILE:  Complex.pm
#
#  DESCRIPTION:  More complex queries
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Matthias Bethke (mbethke), matthias@towiski.de
#      COMPANY:  Zonarix S.A.
#      VERSION:  1.0
#      CREATED:  09/11/2011 18:24:00 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use parent 'Ashafix::Schema::Base';
use Ashafix::Model;

our %queries = (
    # TODO handle pgsql booleans (db_get_boolean)
    get_domains_for_admin => "SELECT d.domain
    FROM %table_domain d
    LEFT JOIN %table_domain_admins a ON d.domain=a.domain 
    WHERE a.username=? AND d.active=1 AND d.backupmx=0
    ORDER BY a.domain",
    delete_everything   => "DELETE FROM %table_domain",
);

our %snippets = (
    get_domain_stats => "SELECT d.*,
    COUNT(DISTINCT m.username) AS mailbox_count
    FROM %table_domain d
    LEFT JOIN %table_mailbox m ON d.domain=m.domain
    WHERE d.domain %where_clause
    GROUP BY d.domain, d.description, d.aliases, d.mailboxes, d.maxquota,
    d.quota, d.transport, d.backupmx, d.created, d.modified, d.active
    ORDER BY d.domain",

    get_aliases_per_domain => "SELECT d.domain,
    COUNT(DISTINCT a.address) AS alias_count
    FROM %table_domain d
    LEFT JOIN %table_alias a ON d.domain = a.domain
    WHERE d.domain %where_clause
    GROUP BY d.domain
    ORDER BY d.domain",

    get_addresses_by_domain => "SELECT address, goto, modified, active
    FROM %table_alias
    WHERE %sql_domain AND
    NOT EXISTS(SELECT 1 FROM %table_mailbox WHERE username=%table_alias.address)
    %sql_where
    ORDER BY address
    LIMIT ? OFFSET ?",

    getmb_mailbox   => " FROM %table_mailbox m",
    getmb_alias     => " LEFT JOIN %table_alias a ON m.username=a.address ",
    getmb_vacation  => " LEFT JOIN %table_vacation v ON m.username=v.email ",
    getmb_newquota  => " LEFT JOIN %table_quota2 q2 ON m.username=q2.username ",
    getmb_oldquota  => " LEFT JOIN %table_quota q ON m.username=q.username ",
);

# Takes an SQL snippet with placeholder for the WHERE clause and a list of domains;
# returns aggregated stats
# If domain is 'ALL', all domains except the dummy domain ALL will be queried.
sub _all_or_in_query {
    my $self = shift;
    my $sql = shift;
    if('ALL' eq $_[0]) {
        $sql =~ s/%where_clause/!= 'ALL'/;
        shift;
    } else {
        $sql =~ s/%where_clause/$self->sql_in_clause_bindparams(@_)/e;
    }
    return Ashafix::Schema::query($sql, @_);
}

sub get_domain_stats {
    my $self = shift;
    return $self->_all_or_in_query($snippets{get_domain_stats}, @_);
}

sub get_aliases_per_domain {
    my $self = shift;
    return $self->_all_or_in_query($snippets{get_aliases_per_domain}, @_);
}

sub get_addresses_by_domain {
    my $self = shift;
    my %args = @_;
    my ($sql_domain, $sql_where);
    my $sql = $snippets{get_addresses_by_domain};
    my @params;

    if(defined $args{search} and length $args{search}) {
        $sql_domain = $self->sql_in_clause_bindparams( @{$args{domains}} );
        $sql_where  = "AND (address LIKE ? OR goto LIKE ?)";
        @params     = ( @{$args{domains}}, (("%${args{search}}%") x 2));
    } else {
        $sql_domain = "domain=?";
        $sql_where  = '';
        @params     = $args{domain};
    }
    $sql =~ s/%sql_where/$sql_where/;
    $sql =~ s/%sql_domain/$sql_domain/;
    # TODO do we need a different query for Postgres?
    return Ashafix::Schema::query($sql, @params, map { 0+$_ } @args{qw /limit offset/});
    # TODO modify Postgres result:
    # $row['modified'] = date('Y-m-d H:i', strtotime($row['modified']));
    # $row['active']=('t'==$row['active']) ? 1 : 0;
}

# Hash-style args: 
# - cfg:        application config hashref
# - domains:    arrayref of allowed domains
# - domain:     scalar, TODO
# - search:     search term, may be undef
#
# TODO think long and hard about using DBIx::Class
sub get_mailboxes {
    my $self = shift;
    my %args = @_;
    my $cfg = $args{cfg};
    my @params;

    # Build the query
    my $sql_select = "SELECT m.*";
    my $sql_from   = $snippets{getmb_mailbox};
    my $sql_join;
    my $sql_where  = " WHERE ";
    
    if(defined $args{search} and length $args{search}) {
        my $search_pat = '%' . $args{search} . '%';
        $sql_where .= 'm.domain' . $self->sql_in_clause_bindparams(@{$args{domains}});
        push @params, @{$args{domains}};
        $sql_where .= " AND (m.username LIKE ? OR m.name LIKE ?";
        push @params, ($search_pat) x 2;
        if($cfg->{display_mailbox_aliases}) { 
            $sql_where .= ' OR a.goto LIKE ?';
            push @params, $search_pat;
        }
        $sql_where .= ') ';
    } else {
        $sql_where .= ' m.domain=? ';
        push @params, $args{domain};
    }

    if($cfg->{display_mailbox_aliases}) {
        $sql_select .= ',a.goto ';
        $sql_join   .= $snippets{getmb_alias};
    }
    
    if($cfg->{vacation_control_admin}) {
        $sql_select .= ',v.active AS v_active ';
        $sql_join   .= $snippets{getmb_vacation};
    }
    
    if($cfg->{used_quotas}) {
        if($cfg->{new_quota_table}) {
            $sql_select .= ',q2.bytes as current ';
            $sql_join   .= $snippets{getmb_newquota};
        } else {
            $sql_select .= ',%q.current ',
            $sql_join   .= $snippets{getmb_oldquota};
            $sql_where  .= " AND (q.path='quota/storage' OR q.path IS NULL) ";
        }
    }
    
    my $sql = "$sql_select $sql_from $sql_join $sql_where ORDER BY m.username LIMIT ? OFFSET ?";

    return Ashafix::Schema::query($sql, @params, @args{qw/ limit offset /});
    # TODO
    # if ('pgsql'==$CONF['database_type']) {
    #     // XXX
    #     $row['modified'] = date('Y-m-d H:i', strtotime($row['modified']));
    #     $row['created'] = date('Y-m-d H:i', strtotime($row['created']));
    #     $row['active']=('t'==$row['active']) ? 1 : 0;
    #     if($row['v_active'] == NULL) { 
    #         $row['v_active'] = 'f';
    #     }
    #     $row['v_active']=('t'==$row['v_active']) ? 1 : 0; 
    # }
    
}

1;
