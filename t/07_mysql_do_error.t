# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 07_mysql_do_error.t,v 1.3 2006/03/30 12:08:08 jettero Exp $

use Test;

if( -d "/home/jettero/code/perl/easy2" ) {
    plan tests => 2;

} else {
    plan tests => 1;
}

use DBIx::Easy::MySQL; ok 1;

if( -d "/home/jettero/code/perl/easy2" ) {
    my $dbo = new DBIx::Easy::MySQL("scratch");

    eval { $dbo->do("syntax error!!") };
    ok( $@, qr(error in your SQL syntax) );
}
