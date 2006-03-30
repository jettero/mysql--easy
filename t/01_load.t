

use Test;
plan tests => 1;

eval {
    use DBIx::Easy::SQLite;
    use DBIx::Easy::MySQL;
};

ok (not $@);
