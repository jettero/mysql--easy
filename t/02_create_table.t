

use Test;
plan tests => 2;

use DBI::Easy::SQLite;

if( -f "testdb" ) {
    unlink "testdb" or die "couldn't remove testdb: $!";
}

my $dbo = new DBI::Easy::SQLite("testdb");    ok 1;
   $dbo->do("create table test( supz int )"); ok 2;

