use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('Mod::Conf');
use Mod::Conf;

my $dummy = {
    "version" => "0.0.0",
    "item" => {}
};
my $c = Conf->new($dummy);

ok $c;
isa_ok($c, "Conf");


# ///////////////
# get_config
# ///////////////



done_testing;

