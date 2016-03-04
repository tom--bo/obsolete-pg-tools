package Conf;
use strict;
use warnings;

use parent qw(Class::Accessor);
Conf->mk_accessors(qw(version setting));

1;
