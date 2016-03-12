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
        "item"  => {}
    };
    my @dbs;
    my @confs;
    my $db_cnt = @ARGV;

    for(my $i=0; $i<$db_cnt; $i++) {
        push(@dbs, Setting->new($default));
        push(@confs, Conf->new($dummy));
        $dbs[$i]->setArgs($ARGV[$i]);
        $confs[$i]->get_config($dbs[$i]);
    }

    &compare_version(\@confs);
    my $diff_keys = &get_different_keys(\@confs);
    if(scalar(@$diff_keys) == 0) {
        print "There is no differenct settings.\n" ;
        return;
    }
    &print_difference(\@confs, \@dbs, $diff_keys);
}

sub compare_version {
    my $confs = shift @_;
    my $version = @$confs[0]->version;
    for(my $i=1; $i<scalar(@_); $i++) {
        if($version ne @$confs[$i]->version) {
            print "************************\n";
            print " Different Version !!\n";
            print "************************\n";
            return;
        }
    }
}

sub get_different_keys {
    my $confs = shift @_;
    my $db_cnt = scalar(@$confs);
    my $tmp, my $tmp_item;
    my @keys, my @diff_keys;

    for(my $i=0; $i<$db_cnt; $i++) {
        $tmp = @$confs[$i]->item;
        push(@keys, keys(%$tmp));
    }
    @keys = uniq(@keys);
    @keys = sort(@keys);

    for my $key (@keys) {
        for(my $i=0; $i<$db_cnt; $i++) {
            if(!defined @$confs[$i]->item->{$key}){
                @$confs[$i]->item->{$key} = "";
            }
        }

        $tmp_item = @$confs[0]->item->{$key};
        for(my $i=1; $i<$db_cnt; $i++) {
            if($tmp_item ne @$confs[1]->item->{$key}) {
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
            printf("  %-15s - %-20s\n", @$dbs[$j]->host, @$confs[$j]->item->{$key});
        }
    }
}


1;

