use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('Mod::Setting');
use Mod::Setting;

my $default = {
    "host"     => "localhost",
    "port"     => 5432,
    "user"     => "postgres",
    "password" => "",
    "database" => "postgres"
};

my $s = Setting->new($default);

ok $s;
isa_ok($s, "Setting");


# ///////////////
# setArgs
# ///////////////




done_testing;

