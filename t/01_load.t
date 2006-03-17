

use Test;
plan tests => 1;

eval {
    use DBI::Easy::SQLite;
};

ok (not $@);
