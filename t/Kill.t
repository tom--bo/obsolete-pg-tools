use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('Mod::Kill');
use Mod::Kill;

my $opt = {
    "help"                   => 0,
    "ignore_match_query"     => '',
    "ignore_match_state"     => '',
    "ignore_query_user_name" => '',
    "kill"                   => '',
    "match_query"            => '',
    "match_state"            => '',
    "print"                  => 0,
    "query_user_name"        => '',
    "run_time"               => 0,
    "version"                => 0,
};

my $k = Kill->new($opt);

ok $k;
isa_ok($k, "Kill");


# ///////////////
# search_queries
# ///////////////



# ///////////////
# kill_queries
# ///////////////



done_testing;

