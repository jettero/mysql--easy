# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 05_mysql_connect.t,v 1.4 2006/03/30 12:08:08 jettero Exp $

use Test;

if( -d "/home/jettero/code/perl/easy2" ) {
    plan tests => 5;
} else {
     plan tests => 1;
}

use MySQL::Easy; ok 1;

if( -d "/home/jettero/code/perl/easy2" ) {
    # no good without the tables set up...
    my $dbo = new MySQL::Easy("stocks"); $dbo->set_user("jettero");
    ok $dbo; # 2
    my $show = $dbo->ready("show tables");
    ok $show; # 3

    my $h = $dbo->selectall_hashref( $show, "Tables_in_stocks" );
    ok( ref $h, "HASH");

    print STDERR " ", join(", ", keys %$h), "\n";

    my ($table, $x) = (undef, 0);
    $h = $dbo->bind_execute("show tables", \( $table ));
    die " ... " . $dbo->errstr unless $h;
    while( fetch $h ) {
        $x ++;
    }

    ok $x > 1;
}
