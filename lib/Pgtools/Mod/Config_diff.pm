package Config_diff;
use strict;
use warnings;

use Mod::Setting;
use Mod::Conf;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use parent qw(Class::Accessor);
Config_diff->mk_accessors(qw(argv));

sub exec {
    my $default = {
        "host"     => "localhost",
        "port"     => "5432",
        "user"     => "postgres",
        "password" => "",
        "database" => "postgres"
    };
    my $dummy = {
        "version"  => "0.0.0",
        "setting"  => {}
    };
    my @dbs;
    my @confs;
    my $db_cnt = @ARGV;

    for(my $i=0; $i<$db_cnt; $i++) {
        push(@dbs, Setting->new($default));
        push(@confs, Conf->new($dummy));
        $dbs[$i]->setArgs($ARGV[$i]);
    }
    for(my $i=0; $i<=$db_cnt; $i++) {
        my $dbh = DBI->connect(
            "dbi:Pg:dbname=".$dbs[$i]->database.";host=".$dbs[$i]->host.";port=".$dbs[$i]->port,
            $dbs[$i]->user,
            $dbs[$i]->password
        ) or die "$!\n Error: failed to connect to DB.\n";

        my $sth = $dbh->prepare("
            SELECT name, setting FROM pg_settings
        ");
        $sth->execute();

        while (my $ary_ref = $sth->fetchrow_arrayref) {
            my $tmp = $confs[$i]->setting;
            $tmp = {%{$tmp}, (@$ary_ref[0] => @$ary_ref[1])};
            $confs[$i]->setting($tmp);
        }
        $sth = $dbh->prepare("
            SELECT version()
        ");
        $sth->execute();
        my $ref = $sth->fetchrow_arrayref;
        my @v = split(/ /, @$ref[0], -1);
        $confs[$i]->version($v[1]);

        $sth->finish;
        $dbh->disconnect;
    }

    &compare_version(\@confs);
    &compare_conf(\@confs, \@dbs);
}

sub compare_version {
    my $confs = shift @_;
    if(@$confs[0]->version ne @$confs[1]->version) {
        print "************************\n";
        print " Version is defferent!! \n";
        print "************************\n";
    }
}

sub compare_conf {
    my ($confs, $dbs) = @_;
    my @keys =  (keys @$confs[0]->setting, keys @$confs[1]->setting);
    @keys = uniq(@keys);
    @keys = sort(@keys);
    my $cnt = 0;

    print sprintf("--------------------------------------------------------------------------------------------\n");
    print sprintf("%-35s | %-35s | %-35s\n", "columm name", @$dbs[0]->host, @$dbs[1]->host);
    print sprintf("--------------------------------------------------------------------------------------------\n");
    for my $key (@keys) {
        if(!defined @$confs[0]->setting->{$key}){
            @$confs[0]->setting->{$key} = "";
        }
        if(!defined @$confs[1]->setting->{$key}){
            @$confs[1]->setting->{$key} = "";
        }
        if(@$confs[0]->setting->{$key} ne @$confs[1]->setting->{$key}) {
            $cnt += 1;
            print sprintf("%-35s | %-35s | %-35s\n", $key, @$confs[0]->setting->{$key}, @$confs[1]->setting->{$key});
        }
    }
    print "There is no differenct settings.\n" if $cnt == 0;
}

sub print_help {
    print <<OUT;
    $0 [-hv] arg1 arg2

    Show different settings between 2 PostgreSQL databases.

    Options:
      -help:  show this help.

    Args:
      This command need 2 argument which is string to specify the databases.
      1 argument should contain hostname, port, username, password, and database.
      These should be separated by  colon(:). 
      You can omit these pieces except hostname, and then you should insert no character between colons.
      Default setting is applied when you omit argument pieces. 
      Default setting is ...
        Hostname: localhost 
        Port    : 5432
        Username: postgres
        Password: '' (empty)
        Database: postgres
OUT
}



1;
