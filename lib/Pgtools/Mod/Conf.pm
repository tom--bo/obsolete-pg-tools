package Conf;
use strict;
use warnings;

use parent qw(Class::Accessor);
use Data::Dumper;
Conf->mk_accessors(qw(version item));

sub get_config {
    my ($self, $setting) = @_;
    
    my $dbh = DBI->connect(
        "dbi:Pg:dbname=".$setting->database.";host=".$setting->host.";port=".$setting->port,
        $setting->user,
        $setting->password
    ) or die "$!\n Error: failed to connect to DB.\n";

    my $sth = $dbh->prepare("
        SELECT name, setting FROM pg_settings
    ");
    $sth->execute();

    while (my $ary_ref = $sth->fetchrow_arrayref) {
        my $tmp = $self->item;
        $tmp = {%{$tmp}, (@$ary_ref[0] => @$ary_ref[1])};
        $self->item($tmp);
    }
    $sth = $dbh->prepare("
        SELECT version()
    ");
    $sth->execute();
    my $ref = $sth->fetchrow_arrayref;
    my @v = split(/ /, @$ref[0], -1);
    $self->version($v[1]);

    $sth->finish;
    $dbh->disconnect;
}

1;
