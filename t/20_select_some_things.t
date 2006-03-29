

use Test;
plan tests => 10;

use DBI::Easy::SQLite;

if( -f "testdb" ) {
    unlink "testdb" or die "couldn't remove testdb: $!";
}

my $dbo = new DBI::Easy::SQLite("testdb");
my $sth = $dbo->ready("select * from test order by supz");

execute $sth or die $dbo->errstr;

my $x = 1;
while( my $h = fetchrow_hashref $sth ) {
    ok( $h->{supz}, $x ++ );
}
