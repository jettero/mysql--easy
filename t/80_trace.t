
use strict;
use Test;
use Cwd;
use MySQL::Easy;

unless( getcwd() eq "/home/jettero/code/cpan/easy" ) {
    plan tests => 1;
    ok(1);
    exit 0;
}

plan tests => 1;

open STDERR, ">", "/tmp/stderr.$$.$<";
END { unlink "/tmp/stderr.$$.$<" }

my $dbo = MySQL::Easy->new("scratch");

$dbo->trace(1);
$dbo->ping;

open my $in, "<", "/tmp/stderr.$$.$<";
while(<$in>) {
    # <- ping= ( 1 ) [1 items] at Easy.pm line 196
    if( m/ping\s*=.*?\(\s*\d+\s*\).*?items/ ) {
        ok(1);
        last;
    }
}
