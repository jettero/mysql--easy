# vi:fdm=marker fdl=0 syntax=perl:
# $Id: 05_mysql_connect.t,v 1.1 2006/03/29 14:01:23 jettero Exp $

use Test;

if( -d "/home/jettero/code/perl/easy" ) {
    plan tests => 5;
} else {
     plan tests => 1;
}

use DBI::Easy::MySQL; ok 1;

if( -d "/home/jettero/code/perl/easy" ) {
    # no good without the tables set up...
    my $dbo = new DBI::Easy::MySQL("stocks"); $dbo->set_user("jettero");
    ok $dbo; # 2
    my $show = $dbo->ready("show tables");
    ok $show; # 3

    my $h = $dbo->selectall_hashref( $show, "Tables_in_stocks" );
    ok ref($h) eq "HASH";

    print STDERR " ", join(", ", keys %$h), "\n";

    my ($table, $x) = (undef, 0);
    $h = $dbo->bind_execute("show tables", \( $table ));
    die " ... " . $dbo->errstr unless $h;
    while( fetch $h ) {
        $x ++;
    }

    ok $x > 1;
}
