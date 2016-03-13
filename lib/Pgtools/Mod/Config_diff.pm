package Config_diff;
use strict;
use warnings;

use Mod::Connection;
use Mod::Conf;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use parent qw(Class::Accessor);

sub exec {
    my $default = {
        "host"     => "localhost",
        "port"     => "5432",
        "user"     => "postgres",
        "password" => "",
        "database" => "postgres"
    };
    my @dbs, my @confs;
    my $db_cnt = @ARGV;

    for(my $i=0; $i<$db_cnt; $i++) {
        my $db = Connection->new($default);
        $db->setArgs($ARGV[$i]);
        $db->create_connection();

        my $c = get_db_config($db);

        push(@dbs, $db);
        push(@confs, Conf->new($c));

        $db->dbh->disconnect;
    }

    my $is_different = &check_version(\@confs);
    &warn_difference() if $is_different == 1;;

    my $diff_keys = &get_different_keys(\@confs);
    if(scalar(@$diff_keys) == 0) {
        print "There is no differenct settings.\n" ;
        return;
    }
    &print_difference(\@confs, \@dbs, $diff_keys);
}

sub check_version {
    my $confs = shift @_;
    my $version = @$confs[0]->version;
    for(my $i=1; $i<scalar(@_); $i++) {
        if($version ne @$confs[$i]->version) {
            return 1;
        }
    }
    return 0;
}

sub warn_difference {
    print "************************\n";
    print "  Different Version !!  \n";
    print "************************\n";
}

sub get_different_keys {
    my $confs = shift @_;
    my $db_cnt = scalar(@$confs);
    my $tmp, my $tmp_item;
    my @keys, my @diff_keys;

    for(my $i=0; $i<$db_cnt; $i++) {
        $tmp = @$confs[$i]->items;
        push(@keys, keys(%$tmp));
    }
    @keys = uniq(@keys);
    @keys = sort(@keys);

    for my $key (@keys) {
        for(my $i=0; $i<$db_cnt; $i++) {
            if(!defined @$confs[$i]->items->{$key}){
                @$confs[$i]->items->{$key} = "";
            }
        }

        $tmp_item = @$confs[0]->items->{$key};
        for(my $i=1; $i<$db_cnt; $i++) {
            if($tmp_item ne @$confs[1]->items->{$key}) {
                push(@diff_keys, $key);
            }
        }
    }
    return \@diff_keys;
}

sub print_difference {
    my ($confs, $dbs, $diff_keys) = @_;
    my $db_cnt = scalar(@$confs);
    my $key_cnt = scalar(@$diff_keys);
    for(my $i=0; $i<$key_cnt; $i++) {
        my $key = @$diff_keys[$i];
        printf("%-15s------------\n", $key);
        for(my $j=0; $j<$db_cnt; $j++) {
            printf("  %-15s - %-20s\n", @$dbs[$j]->host, @$confs[$j]->items->{$key});
        }
    }
}

sub get_db_config {
    my $db = shift @_;
    
    my $sth = $db->dbh->prepare("SELECT name, setting FROM pg_settings");
    $sth->execute();

    my $items = {};
    while (my $hash_ref = $sth->fetchrow_hashref) {
        my %row = %$hash_ref;
        $items = {%{$items}, $row{name} => $row{setting}};
    }

    $sth = $db->dbh->prepare("SELECT version()");
    $sth->execute();

    my $ref = $sth->fetchrow_arrayref;
    my @v = split(/ /, @$ref[0], -1);

    $sth->finish;

    my $ret = {
        "version" => $v[1],
        "items"    => $items 
    };

    return $ret;
}



1;

