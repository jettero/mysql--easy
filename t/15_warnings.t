# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 15_warnings.t,v 1.1 2006/03/29 14:01:23 jettero Exp $

use Test;

if( -d "/home/jettero/code/perl/easy" ) {
    use strict;
    use MySQL::Easy;

    plan tests => 2;

    my $dbo = new MySQL::Easy("scratch");
    my $bad = ready $dbo("insert into testy_table set enumer ='not good!'");
    my $oki = ready $dbo("insert into testy_table set enumer ='good'");

    $dbo->do("create temporary table testy_table( enumer enum('good', 'ugly', 'potato', 'OMFGLMAOBBQ') )");

    execute $bad or die $dbo->errstr;
    unless( check_warnings $dbo )        # example real-call: check_warnings $dbo or die $@ 
         { ok( $@ =~ m/truncated/ ) } 
    else { ok( 0 ) }

    execute $oki or die $dbo->errstr;
    ok( check_warnings $dbo );

} else {
    plan tests => 1;
    ok(1);
}
