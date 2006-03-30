

use Test;
plan tests => 2;

eval { use DBIx::Easy::SQLite }; ok( not $@ );
eval { use DBIx::Easy::MySQL  }; ok( not $@ );
