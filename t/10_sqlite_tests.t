

use Test;
use strict;
no warnings;
use DBI::Easy::SQLite;

my $df = "./testdb";

if( -f $df ) {
    unlink $df or die "couldn't unlink $df: $!"
}

plan tests => 23;

my $dbo = new DBI::Easy::SQLite($df);

eval { $dbo->do("syntax errors please!??!") }; 
ok( $@, qr{unrecognized token} );
# DBD::SQLite::db prepare failed: unrecognized token: "!?"(1) at dbdimp.c

my $sth = $dbo->ready("syntax errors please?!??!");
if( execute $sth ) {
    ok(0);

} else {
    ok( $dbo->errstr, qr(unrecognized token) );
}

$dbo->do("create table test( supz int )") or die $dbo->errstr; ok 1;

my $ins = $dbo->ready("insert into test(supz) values(?)");
my $get = $dbo->ready("select * from test order by supz");

for ( 1 .. 10 ) {
    ok( $ins->execute( $_ ) );
}

my $x = 1;
execute $get or die $dbo->errstr;
while( my $h = fetchrow_hashref $get ) {
    ok( $h->{supz}, $x ++ );
}
