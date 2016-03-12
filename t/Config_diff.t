use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('Mod::Config_diff');
use Mod::Config_diff;

my @args = ("192.168.33.21:5432:postgres::", "192.168.33.22:5432:postgres::");
my $s = Config_diff->new({"argv" => \@ARGV});

ok $s;
isa_ok($s, "Config_diff");

done_testing;

# ///////////////
# check_version
# ///////////////



# ///////////////
# get_different_key
# ///////////////





