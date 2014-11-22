
use strict;
use Test;
use Cwd;
use MySQL::Easy;

# BLAH {{{
unless( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    plan tests => 1;
    ok(1);
    exit 0;
}

sub kill_me {
    my $dbo = shift;
    my $sth = $dbo->ready("show processlist");

    $sth->execute;
    while( my ($Id, $User, $Host, $db, $Command, $Time, $State, $Info, $Progress) = $sth->fetchrow_array ) {
        if( $Info eq "show processlist" ) {
            $dbo->do("kill ?", $Id);
            return 1;
        }
    }

    return;
}
# }}}

plan tests => 7;

GROUP1: {
    my $dbo = MySQL::Easy->new("scratch");
       $dbo->do("create table if not exists t85( a int, b int )");

    my $sth = $dbo->ready("insert into t85(a,b) values(?,?)");

    $sth->execute and ok(1);
    $dbo->handle->disconnect;
    $sth->execute and ok(1);
    ok( $sth->{repair}, 1 );
    $sth->execute and ok(1);
    ok( $sth->{repair}, 1 );
    $dbo->handle->disconnect;
    $sth->execute and ok(1);
    ok( $sth->{repair}, 2 );
}
