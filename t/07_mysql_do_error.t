# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 07_mysql_do_error.t,v 1.2 2006/03/29 18:03:19 jettero Exp $

use Test;

if( -d "/home/jettero/code/perl/easy2" ) {
    plan tests => 2;

} else {
    plan tests => 1;
}

use DBI::Easy::MySQL; ok 1;

if( -d "/home/jettero/code/perl/easy2" ) {
    my $dbo = new DBI::Easy::MySQL("scratch");

    eval { $dbo->do("syntax error!!") };
    ok( $@, qr(error in your SQL syntax) );
}
