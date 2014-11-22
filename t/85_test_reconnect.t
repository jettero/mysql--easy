
use strict;
use Test;
use Cwd;
use MySQL::Easy;

unless( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    plan tests => 1;
    ok(1);
    exit 0;
}

plan tests => 11 + 8 + 14;

# don't accidentally run this regardless of exit above
eval'
END {
    my $dbo = MySQL::Easy->new("scratch");
       $dbo->do("drop table if exists t85");
}
';

GROUP1: {
    my $dbo = MySQL::Easy->new("scratch");
       $dbo->do("drop table if exists t85");
       $dbo->do("create table t85( a int, b int )");

    my $sth = $dbo->ready("insert into t85(a,b) values(?,?)");

    my $x = 0;

    ok( $sth->execute($x++, $$) );

    $dbo->handle->disconnect;
    ok( $sth->execute($x++, $$) );
    ok( $sth->{repair}, 1 );

    $dbo->handle->disconnect;
    ok( $sth->execute($x++, $$) );
    ok( $sth->{repair}, 2 );

    $dbo->handle->disconnect;
    ok( $sth->execute($x++, $$) );
    ok( $sth->{repair}, 3 );

    my $res = $dbo->firstcol("select a from t85");
    ok( $res->[$_], $_ ) for 0 .. $#$res;
}

GROUP2: {
    my $dbo = MySQL::Easy->new("scratch");

    {
        my $res = $dbo->firstcol("select a from t85");
        ok( $res->[$_], $_ ) for 0 .. $#$res;
    }

    # this is really the trivial case, since we don't have to repair anything
    {
        $dbo->handle->disconnect;

        my $res = $dbo->firstcol("select a from t85");
        ok( $res->[$_], $_ ) for 0 .. $#$res;
    }
}

GROUP3: {
    my $dbo = MySQL::Easy->new("scratch");
    my $sth = $dbo->ready("select a from t85");
    my $res = $dbo->firstcol($sth);

    ok( $res->[$_], $_ ) for 0 .. $#$res;

    # this case is why I built the test

    $dbo->handle->disconnect;
    $res = $dbo->firstcol($sth);
    ok( $res->[$_], $_ ) for 0 .. $#$res;
    ok( $sth->{repair}, 1 );

    $dbo->handle->disconnect;
    $res = $dbo->firstcol($sth);
    ok( $res->[$_], $_ ) for 0 .. $#$res;
    ok( $sth->{repair}, 2 );
}
