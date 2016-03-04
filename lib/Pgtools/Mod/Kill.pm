package Kill;
use strict;
use warnings;
use DateTime;
use DateTime::Format::Strptime;
use DBI;

use Mod::Connection;
use Data::Dumper;
use parent qw(Class::Accessor);
Kill->mk_accessors(qw(argv opt));

our ($now, $qt);
our $qt_format = DateTime::Format::Strptime->new(
    pattern => '%Y-%m-%d %H:%M:%S.%N'
);
our $start_time = DateTime->now( time_zone => 'Asia/Tokyo' );

sub main {
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
    my $dbh = DBI->connect("dbi:Pg:dbname=".$db->database.";host=".$db->host.";port=".$db->port,$db->user,$db->password) or die "$!\n Error: failed to connect to DB.\n";

    my $sth = $dbh->prepare("
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

    my @pids = &search_queries($db, $sth, $self->opt);

    if($self->opt->{kill}){
        &kill_queries($dbh, $self->opt, \@pids);
    }

    $sth->finish;
    $dbh->disconnect;
}

sub kill_queries {
    my ($dbh, $opt, $pids) = @_;
    my ($sth, $now);

    foreach my $val (@$pids) {
        $sth = $dbh->prepare("SELECT pg_terminate_backend(".$val.");");
        $now = DateTime->now( time_zone => 'local' );
        print "killed-pid: " . $val . ", at " .  $now->strftime('%Y/%m/%d %H:%M:%S') . "\n" if $opt->{print};
        $sth->execute();
    }
}

sub search_queries {
    my ($db, $sth, $opt) = @_;
    my @pids;

    while (my $ary_ref = $sth->fetchrow_arrayref) {
        if($db->database ne @$ary_ref[0]) {
            next;
        }
        if($opt->{match_state} ne '' and @$ary_ref[11] ne $opt->{match_state}) { 
            next;
        }
        if($opt->{match_query} ne '' and @$ary_ref[12] !~ /$opt->{match_query}/im ) {
            next;
        }
        if($opt->{ignore_query_user_name} ne '' and @$ary_ref[1] eq $opt->{ignore_query_user_name}) { 
            next;
        }
        if($opt->{ignore_match_state} ne '' and @$ary_ref[11] eq $opt->{ignore_match_state}) { 
            next;
        }
        if($opt->{ignore_match_query} ne '' and @$ary_ref[12] =~ /$opt->{ignore_match_query}/im ) {
            next;
        }

        if($opt->{run_time} != 0) {
            $qt = $qt_format->parse_datetime(@$ary_ref[6]);
            $qt->set_time_zone('Asia/Tokyo');
            my $diff = $start_time->epoch() - $qt->epoch();
            if($diff < $opt->{run_time}) {
                next;
            }
        }
        if($opt->{print} and !$opt->{kill}) {
            &print_query($ary_ref);
        }
        push(@pids, $ary_ref->[1]);
    }
    return @pids;
}

sub print_query {
    my $ary_ref = shift @_;
    print "-------------------------------\n";
    print "pid: @$ary_ref[1]"."\n";
    print "start_time: @$ary_ref[6]"."\n";
    print "state: @$ary_ref[11]"."\n";
    print "query: @$ary_ref[12]"."\n";
}

sub print_help {
    print <<OUT;
    $0 -help | [-(options below)]

    Kill queries which are matched specified regular expression.

  Options:
    -db  database:       set the database name
    -h   host:           host (localhost)
    -help:               show this help
    -ignore_match_query: except matching query
    -ignore_match_state: except matching state
    -kill:               kill query which matched condition
    -mq  match_query:    query match
    -ms  match_state:    state match
    -pr  print:          print killed queries info
    -p   passward:       set password
    -port:               port number
    -query_user_name:     user who exec query
    -r   run_time:       execute time 
    -u   user:           Postgres user name 
    -v   version:        version
OUT
}



1;
