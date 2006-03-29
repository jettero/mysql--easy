# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 07_mysql_do_error.t,v 1.1 2006/03/29 17:57:29 jettero Exp $

use Test;

if( -d "/home/jettero/code/perl/easy2" ) {
    plan tests => 2;

} else {
    plan tests => 1;
}

use DBI::Easy::MySQL; ok 1;

if( -d "/home/jettero/code/perl/easy2" ) {
    my $dbo = new DBI::Easy::MySQL("stocks"); $dbo->set_user("jettero");

    eval { $dbo->do("syntax error!!") };
    ok( $@, qr(error in your SQL syntax) );
}
