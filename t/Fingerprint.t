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
my $s = Fingerprint->new();

ok $s;
isa_ok($s, "Fingerprint");

# ///////////////
# normalize_spaces
# ///////////////

is($s->normalize_spaces("SELECT * FROM user WHERE id   =     ?;"), "SELECT * FROM user WHERE id = ?;");
is($s->normalize_spaces("SELECT * FROM user WHERE id   =   ?  ;"), "SELECT * FROM user WHERE id = ?;");


# ///////////////
# symbolize_query
# ///////////////

is($s->symbolize_query("SELECT * FROM user WHERE id = 100;"), "SELECT * FROM user WHERE id = ?;");
is($s->symbolize_query("SELECT * FROM user WHERE id   =     100 LIMIT 3;"), "SELECT * FROM user WHERE id = ? LIMIT ?;");
is($s->symbolize_query("SELECT * FROM user2 WHERE id =100;"), "SELECT * FROM user2 WHERE id = ?;");
is($s->symbolize_query("SELECT * FROM user WHERE name ='hoge';"), "SELECT * FROM user WHERE name = ?;");
is($s->symbolize_query('SELECT * FROM user WHERE name like "bar%";'), "SELECT * FROM user WHERE name like ?;");
is($s->symbolize_query('SELECT * FROM user WHERE name like "bar%" and address like "foo";'), "SELECT * FROM user WHERE name like ?;");

}



done_testing;

