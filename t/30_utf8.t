
use strict;
use utf8;
use Test;
use Cwd;
use DBI qw(:utils);

use DBD::mysql;

if( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    use strict;
    use MySQL::Easy;

    plan tests => 4;

    my $dbo = new MySQL::Easy("scratch");

    my $test_value = "ポル — über ☥";
    ok(length $test_value, 11); # testing myself, not the package so much... meh
    ok( data_string_desc($test_value), qr(UTF8 on.*?11 characters 20 bytes) );

    data_string_desc($test_value);

    $dbo->do("drop table if exists easy_test");
    $dbo->do('create table easy_test( testfield varchar(255) character set utf8 not null )');

    $dbo->do("set character set utf8");
    $dbo->do("set names utf8");

    my $put = $dbo->ready("replace into easy_test set testfield=?");
    my $get = $dbo->ready("select testfield from easy_test");

    $put->execute($test_value);
    $get->bind_execute(\my $val);
    $get->fetch;

    # utf8::decode($val);

    ok( data_string_desc($val), qr(UTF8 on.*?11 characters 20 bytes) );
    ok( $val, $test_value );


} else {
    plan tests => 1;
    ok(1);
}
