
use strict;
use Test;
use Cwd;

if( getcwd() eq "/home/jettero/code/perl/easy" ) {
    plan tests => 2;

} else {
    plan tests => 1;
}

use MySQL::Easy; ok 1;

if( getcwd() eq "/home/jettero/code/perl/easy" ) {
    my $dbo = new MySQL::Easy("scratch");

    eval { $dbo->do("syntax error!!") };
    ok( $@, qr(error in your SQL syntax) );
}
