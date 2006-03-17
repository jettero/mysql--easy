# $Id: Easy.pm,v 1.1 2006/03/17 18:58:57 jettero Exp $

package DBI::Easy::SQLite;

use strict;
use DBI;
use Carp;

use base "DBI";

sub new {
    my $class = shift;
    my $file  = shift; croak "you must pass a filename to $class";
    my $this;
    
    eval { $this = DBI->connect("dbi:SQLite:$file","","") };
    croak "problem with SQLite or your filename ($file) or something: $@" if $@;

    return $this;
}
