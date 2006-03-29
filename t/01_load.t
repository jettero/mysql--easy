

use Test;
plan tests => 1;

eval {
    use DBI::Easy::SQLite;
    use DBI::Easy::MySQL;
};

ok (not $@);
