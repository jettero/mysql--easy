
eval "use DBD::SQLite";
my $sqlite = ($@ ? 0 : 1);

use Test;
plan tests => 2;

if( $sqlite ) { eval { use DBIx::Easy::SQLite }; ok( not $@ ); } else { skip(1) }
eval { use DBIx::Easy::MySQL  }; ok( not $@ );
