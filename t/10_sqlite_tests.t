

use Test;
use strict;
use DBI::Easy::SQLite;

my $df = "./testdb";

if( -f $df ) {
    unlink $df or die "couldn't unlink $df: $!"
}

plan tests => 21;

my $dbo = new DBI::Easy::SQLite($df);
my $cre = $dbo->ready("create table test( supz int )");
my $ins = $dbo->ready("insert into test set supz=?");
my $get = $dbo->ready("select * from test order by supz");

ok( $cre->execute );

for ( 1 .. 10 ) {
    ok( $ins->execute( $_ ) );
}

my $x = 1;
execute $get or die $dbo->errstr;
while( my $h = fetchrow_hashref $get ) {
    ok( $h->{supz}, $x ++ );
}
