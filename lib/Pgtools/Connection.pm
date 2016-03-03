package Connection;
use strict;
use warnings;

use parent qw(Class::Accessor);
Connection->mk_accessors(qw(host port user password database));

1;
