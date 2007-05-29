# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 25_ready_selectall.t,v 1.3 2006/03/30 12:08:08 jettero Exp $

use Test;

if( -d "/home/jettero/code/perl/easy2" ) {
    use strict;
    use MySQL::Easy;

    plan tests => 3;

    my $dbo = new MySQL::Easy("scratch");

    $dbo->do("drop table if exists easy_test");
    $dbo->do('create table easy_test( id int unsigned not null auto_increment primary key )');

    my $put = $dbo->ready("insert into easy_test set id=?");
    $put->execute( 7 ) or die $dbo->errstr;

    ALL1: {
        my $all = $dbo->firstcol("select id from easy_test");
        ok( $all->[0], 7 );
    }

    ALL2: {
        my $get = $dbo->ready("select id from easy_test");
        my $all = $dbo->selectall_arrayref($get->{sth});
        ok( $all->[0][0], 7 );
    }

    ALL3: {
        my $get = $dbo->ready("select id from easy_test");
        my $all = $dbo->selectall_arrayref($get);
        ok( $all->[0][0], 7 );
    }

} else {
    plan tests => 1;
    ok(1);
}
