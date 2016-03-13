package Conf;
use strict;
use warnings;

use parent qw(Class::Accessor);
use Data::Dumper;
Conf->mk_accessors(qw(version items));

1;
