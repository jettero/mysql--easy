# $Id: SQLite.pm,v 1.3 2006/03/29 13:57:28 jettero Exp $

package DBI::Easy::SQLite;

use strict;
use DBI;
use Carp;
use base "DBI";

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my $file  = shift; croak "you must pass a filename to $class" unless length $file;
    my $this  = bless {}, $class;
    
    eval { $this->{db} = DBI->connect("dbi:SQLite:$file","","") };
    croak "problem with SQLite or your filename ($file) or something: $@" if $@;

    return $this;
}

sub ready {
    my $this = shift;

    return $this->prepare(@_);
}
