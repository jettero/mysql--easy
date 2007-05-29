
use Test;
plan tests => 1;

eval { use MySQL::Easy  }; ok( not $@ );
