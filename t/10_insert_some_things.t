

use Test;
plan tests => 10;

use DBI::Easy::SQLite;

if( -f "testdb" ) {
    unlink "testdb" or die "couldn't remove testdb: $!";
}

my $dbo = new DBI::Easy::SQLite("testdb");
my $sth = $dbo->ready("insert into test set supz=?");

for( 1 .. 10 ) {
    my $r = $sth->execute( 1 );
    ok( not $r );
}
