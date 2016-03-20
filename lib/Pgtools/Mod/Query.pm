package Query;
use strict;
use warnings;

use parent qw(Class::Accessor);
use Data::Dumper;
Query->mk_accessors(qw(datname xact_start query_start state query));

1;
