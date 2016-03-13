package Kill;
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
use DBI;

use Mod::Connection;
use Mod::Query;
use Data::Dumper;
use parent qw(Class::Accessor);
Kill->mk_accessors(qw(help ignore_match_query ignore_match_state ignore_query_user_name kill match_query match_state print query_user_name run_time version));

our ($now, $qt);
our $qt_format = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S.%N'
);
our $start_time = DateTime->now( time_zone => 'Asia/Tokyo' );

sub exec {
    my $self = shift;
    my $default = {
        "host"     => "localhost",
        "port"     => "5432",
        "user"     => "postgres",
        "password" => "",
        "database" => "postgres"
    };

    my $db = Connection->new($default);
    $db->setArgs(shift @ARGV);
    $db->create_connection();

    # return hash reference
    my $queries = &search_queries($self, $db);

    if($self->print and !$self->kill) {
        &print_query($queries);
    }
    if($self->kill){
        &kill_queries($db, $self, $queries);
    }

    $db->dbh->disconnect;
}

sub kill_queries {
    my ($db, $self, $queries) = @_;
    my ($sth, $now);

    foreach my $pid (keys(%$queries)) {
        $sth = $db->dbh->prepare("SELECT pg_terminate_backend(".$pid.");");
        $now = DateTime->now( time_zone => 'local' );
        $sth->execute();
        if($self->print) {
            print "killed-pid: ".$pid.", at ".$now->strftime('%Y/%m/%d %H:%M:%S')."\n";
            print "query     : ".$queries->{$pid}->{query}."\n";
        }
    }
}

sub search_queries {
    my ($self, $db) = @_;
    my @pids;
    my $queries = {};

    my $sth = $db->dbh->prepare("
        SELECT
            datname,
            pid,
            application_name,
            client_addr,
            client_hostname,
            client_port,
            backend_start,
            xact_start,
            query_start,
            state_change,
            waiting,
            state,
            query
        FROM 
            pg_stat_activity
        WHERE 
            pid <> pg_backend_pid()
    ");
    $sth->execute();

    while (my $ary_ref = $sth->fetchrow_arrayref) {
        if($db->database ne @$ary_ref[0]) {
            next;
        }
        if($self->match_state ne '' and @$ary_ref[11] ne $self->match_state) { 
            next;
        }
        if($self->match_query ne '' and @$ary_ref[12] !~ /$self->{match_query}/im ) {
            next;
        }
        if($self->ignore_query_user_name ne '' and @$ary_ref[1] eq $self->ignore_query_user_name) { 
            next;
        }
        if($self->ignore_match_state ne '' and @$ary_ref[11] eq $self->ignore_match_state) { 
            next;
        }
        if($self->ignore_match_query ne '' and @$ary_ref[12] =~ /$self->{ignore_match_query}/im ) {
            next;
        }
        if($self->run_time != 0) {
            $qt = $qt_format->parse_datetime(@$ary_ref[6]);
            $qt->set_time_zone('Asia/Tokyo');
            my $diff = $start_time->epoch() - $qt->epoch();
            if($diff < $self->run_time) {
                next;
            }
        }
        my $tmp = {
            "datname" => $ary_ref->[0],
            "pid" => $ary_ref->[1],
            "application_name" => $ary_ref->[2],
            "client_addr" => $ary_ref->[3],
            "client_hostname" => $ary_ref->[4],
            "client_port" => $ary_ref->[5],
            "backend_start" => $ary_ref->[6],
            "xact_start" => $ary_ref->[7],
            "query_start" => $ary_ref->[8],
            "state_change" => $ary_ref->[9],
            "waiting" => $ary_ref->[10],
            "state" => $ary_ref->[11],
            "query" => $ary_ref->[12]
        };
        my $q = Query->new($tmp);
        $queries = {%{$queries},$ary_ref->[1] => $q};
    }
    $sth->finish;

    return $queries;
}

sub print_query {
    my $queries = shift @_;
    foreach my $q (keys(%$queries)) {
        print "-------------------------------\n";
        print "pid       : ".$queries->{$q}->{pid}."\n";
        print "start_time: ".$queries->{$q}->{query_start}."\n";
        print "state     : ".$queries->{$q}->{state}."\n";
        print "query     : ".$queries->{$q}->{query}."\n";
    }
}


1;
