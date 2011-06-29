

use strict;
use MySQL::Easy;
use Test;

my $f = __FILE__;

my $dbo = MySQL::Easy->new("scratch");

$dbo->do("drop table if exists blarg");
$dbo->do("create table blarg( a int, b int, c int )");

my $sth = $dbo->ready("select max a a, b, c from blarg"); my $sth_line = __LINE__;

my $x = eval { $sth->execute }; my $exec_line = __LINE__;

plan tests => 4;

ok( $x, undef );
ok( $@, qr(at $f line $exec_line) );
ok( $@, qr(prepared at $f line $sth_line) );

my @a = $@ =~ m/\b(at\s+line\s+\d+|at\s+\S+\s+line\s+\d+)\b/g;
ok( 0+@a, 2 );
