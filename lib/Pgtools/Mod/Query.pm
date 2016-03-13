package Query;
use strict;
use warnings;

use parent qw(Class::Accessor);
use Data::Dumper;
Query->mk_accessors(qw(datname application_name client_addr client_hostname client_port backend_start xact_start query_start state_change waiting state query));

1;
