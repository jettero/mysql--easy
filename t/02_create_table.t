

use Test;
plan tests => 2;

use DBI::Easy::SQLite;

my $dbo = new DBI::Easy::SQLite; ok 1;
   $dbo->do("create table test( supz int )"); ok 2;


