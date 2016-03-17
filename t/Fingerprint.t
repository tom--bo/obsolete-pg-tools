use strict;
use warnings;

use Test::More;
use Test::MockObject;
use Data::Dumper;
use DBI;

use_ok('Mod::Fingerprint');
use Mod::Fingerprint;

{
my $filename = "";
my $query = "SELECT * from users where id = 100";
my $s = Config_diff->new($filename, $query);

ok $s;
isa_ok($s, "Mod::Fingerprint");

# ///////////////
# symbolize_query
# ///////////////


# ///////////////
# normalize_spaces
# ///////////////

}



done_testing;

