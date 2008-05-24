# $Id: MySQL.pm,v 1.8 2006/05/20 01:27:45 jettero Exp $
# vi:fdm=marker fdl=0:

package MySQL::Easy::sth;

use strict;
use warnings;
use Carp;
use AutoLoader;

our $AUTOLOAD;

# new {{{
sub new {
    my ($class, $mysql_e, $statement) = @_;
    my $this  = bless { s=>$statement, dbo=>$mysql_e }, $class;

    $this->{sth} = $this->{dbo}->handle->prepare( $statement );

    return $this;
}
# }}}
# AUTOLOAD {{{
sub AUTOLOAD {
    my $this = shift;
    my $sub  = $AUTOLOAD;
    my $wa   = wantarray;

    return undef unless $this->{sth};
    # croak "this sth is defunct.  please don't call things on it." unless $this->{sth};

    $sub = $1 if $sub =~ m/::(\w+)$/;

    my $tries = 2;
    if( $this->{sth}->can($sub) ) {
        my @ret;
        my $ret;
        my $warn;

        # warn "DEBUG: FYI, $$-$this is loading $sub()";

        EVAL_IT: eval q/ 
            no strict 'refs';
            local $SIG{__WARN__} = sub { $warn = "@_"; };

            if( $wa ) {
                @ret = $this->{sth}->$sub( @_ );

            } else {
                $ret = $this->{sth}->$sub( @_ );
            }
        /;
         
        if( $warn and not $@ ) {
            $@ = $warn;
            chomp $@;
        }

        if( $@ ) {
            if( $@ =~ m/MySQL server has gone away/ ) {
                if( $sub eq "execute" ) {
                    $this->{sth} = $this->{dbo}->handle->prepare( $this->{s} );
                    $warn = undef;

                    goto EVAL_IT if ((--$tries) > 0);

                } else {
                    croak "MySQL::Easy::sth can only recover during execute(), $@";
                }
            }

            croak "ERROR executing $sub(): $@";
        }

        return ($wa ? @ret : $ret);

    } else {
        croak "$sub is not a member of " . ref($this->{sth});
    }
}
# }}}
# DESTROY {{{
sub DESTROY {
    my $this = shift;

    # warn "MySQL::Easy::sth is dying"; # This is here to make sure we don't normally die during global destruction.
                                        # Once it appeared to function correctly, it was removed.
                                        # Lastly, we would die during global dest iff: our circular ref from new() were not removed.
                                        # Although, to be truely circular, the MySQL::Easy would need to point to this ::sth also
                                        # and it probably doesn't.  So, is this delete paranoid?  Yeah...  meh.
    delete $this->{dbo};
}
# }}}

package MySQL::Easy;

use strict;
use warnings;
use Carp;
use AutoLoader;

use DBI;

our $AUTOLOAD;

use version;
our $VERSION = version->new("2.0.1")->numify;

1;

# AUTOLOAD {{{
sub AUTOLOAD {
    my $this = shift;
    my $sub  = $AUTOLOAD;

    $sub = $1 if $sub =~ m/::(\w+)$/;

    my $handle = $this->handle;

    if( $handle->can($sub) ) {
        no strict 'refs';
        return $handle->$sub( 
            (ref($_[0]) eq "MySQL::Easy::sth" ? $_[0]->{sth} : $_[0]), # cheap and not "gone away" recoverable
            @_[1 .. $#_],
        );

    } else {
        croak "$sub is not a member of " . ref($handle);
    }
}
# }}}

# check_warnings {{{
sub check_warnings {
    my $this = shift;
    my $sth  = $this->ready("show warnings");

    # mysql> show warnings;
    # +---------+------+------------------------------------------+
    # | Level   | Code | Message                                  |
    # +---------+------+------------------------------------------+
    # | Warning | 1265 | Data truncated for column 'var' at row 1 |
    # +---------+------+------------------------------------------+

    my @warnings;

    execute $sth or die $this->errstr;
    while( my $a = fetchrow_arrayref $sth ) {
        push @warnings, $a;
    }
    finish $sth;

    if( @warnings ) {
        $@ = join("\n", map("$_->[0]($_->[1]): $_->[2]", @warnings)) . "\n";

        return 0;
    }

    return 1;
}
# }}}
# new {{{
sub new { 
    my $this  = shift;

    $this = bless {}, $this;

    $this->{dbase} = shift; croak "dbase = '$this->{dbase}'?" unless $this->{dbase};
    $this->{dbh} = $this->{dbase} if ref($this->{dbase}) eq "DBI::db";
    $this->{trace} = shift;

    $this->{dbh}->trace( $this->{trace} ) if $this->{dbh};

    return $this;
}
# }}}
# do {{{
sub do {
    my $this = shift; return unless @_;

    my $r; eval { $r = $this->ready(shift)->execute(@_) }; croak $this->errstr if $@;
    return $r;
}
# }}}
# light_lock {{{
sub light_lock {
    my $this   = shift; return unless @_;
    my $tolock = join(", ", map("$_ read", @_));

    $this->handle->do("lock tables $tolock");
}
# }}}
# lock {{{
sub lock {
    my $this   = shift; return unless @_;
    my $tolock = join(", ", map("$_ write", @_));

    $this->handle->do("lock tables $tolock");
}
# }}}
# unlock {{{
sub unlock {
    my $this = shift;

    $this->handle->do("unlock tables");
}
# }}}
# ready {{{
sub ready {
    my $this = shift;

    return new MySQL::Easy::sth( $this, @_ );
}
# }}}
# firstcol {{{
sub firstcol {
    my $this = shift;
    my $query = shift;

    return $this->handle->selectcol_arrayref($query, undef, @_);
}
# }}}
# thread_id {{{
sub thread_id {
    my $this = shift;

    return $this->handle->{mysql_thread_id};
}
# }}}
# last_insert_id {{{
sub last_insert_id {
    my $this = shift;

    # return $this->firstcol("select last_insert_id()")->[0];
    return $this->handle->{mysql_insertid};
}
# }}}
# errstr (needs to be here, called from AUTOLOAD) {{{
sub errstr {
    my $this = shift;

    return $this->handle->errstr;
}
# }}}
# trace (needs to be here, called from AUTOLOAD) {{{
sub trace {
    my $this = shift;

    $this->handle->trace( @_ );
}
# }}}
# DESTROY {{{
sub DESTROY {
    my $this = shift;

    $this->{dbh}->disconnect if $this->{dbh};
}
# }}}
# handle {{{
sub handle {
    my $this = shift;

    return $this->{dbh} if defined($this->{dbh}) and $this->{dbh}->ping;
    # warn "WARNING: MySQL::Easy is trying to reconnect (if possible)" if defined $this->{dbh};

    ($this->{user}, $this->{pass}) = $this->unp unless $this->{user} and $this->{pass};

    $this->{host}  = "localhost" unless $this->{host};
    $this->{port}  =      "3306" unless $this->{port};
    $this->{dbase} =      "test" unless $this->{dbase};
    $this->{trace} =           0 unless $this->{trace};

    $this->{dbh} =
    DBI->connect("DBI:mysql:$this->{dbase}:host=$this->{host}:port=$this->{port}:mysql_compression=1;mysql_auto_reconnect=1", 
        $this->{user}, $this->{pass});

    croak "failed to generate connection: " . DBI->errstr unless $this->{dbh};

    $this->{dbh}->trace($this->{trace});

    return $this->{dbh};
}
# }}}
# unp {{{
sub unp {
    my $this = shift;

    my ($user, $pass);
    my $mycnf = "$ENV{HOME}/.my.cnf";

    open PASS, $mycnf or die "erorr reading $mycnf to find (otherwise unspecified) username and password: $!";

    my $l;
    while($l = <PASS>) {
        $user = $1 if $l =~ m/user\s*=\s*(.+)/;
        $pass = $1 if $l =~ m/password\s*=\s*(.+)/;

        last if($user and $pass);
    }

    close PASS;

    return ($user, $pass);
}
# }}}
# set_host set_user set_pass {{{
sub set_host { 
    my $this = shift;

    $this->{host} = shift;
}

sub set_port { 
    my $this = shift;

    $this->{port} = shift;
}

sub set_user { 
    my $this = shift;
    
    $this->{user} = shift;
}

sub set_pass { 
    my $this = shift;
    
    $this->{pass} = shift;
}
# }}}
# bind_execute {{{
sub bind_execute {
    my $this = shift;
    my $sql  = shift;

    my $sth = $this->ready($sql);

    $sth->execute            or return undef;
    $sth->bind_columns( @_ ) or return undef;

    return $sth;
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

MySQL::Easy - Perl extension to handle various mundane DBI session related things specific to mysql.

=head1 SYNOPSIS

  use MySQL::Easy;

  my $trace = 0; # the trace arg is optional
  my $dbo = new MySQL::Easy("stocks", $trace);

  #  This is NEW (and totally untested):
  #  $dbo = new MySQL::Easy($existing_DBI_dbh, $trace);

  my $symbols = $dbo->firstcol(
      qq( select symbol from ohlcv where symbol != ?),
      "msft"
  );

  my $q = $dbo->ready("select * from ohlcv where symbol=?");
  for my $s (@$symbols) {
      my @a;

      $q->execute($s) or die $dbo->errstr;
      # Although the regular DBI will reconnect to the server when it loses
      # it's connection, any queries you had previously prepared will fail
      # until it reconnects.  easy::mysql handles all that for you so this
      # execute() will always work, if it's syntactically correct, even if
      # your server connection was lost since the last ready();

      print "@a" while @a = fetchrow_array $q;
  }

=head1 DESCRIPTION

   I don't remember how I used to live without this...
   I do like the way DBI and DBD work, but I wanted something
   _slightly_ prettier... _slightly_ handier.

   Here's the functions MySQL::Easy provides:

   $dbo = new MySQL::Easy( $db_name, $trace );
       # $db_name is the name of the database you're connecting to...
       # If you don't pick anything, it'll pick "test" for you.
       # $trace is a 1 or false, ... it's the DBI->trace() ...

   $dbo->do("sql statement bind=? bind=?", $bind1, $bind2);
       # this immediately executes the sql with the bind vars
       # given.  You can pas in a statement handle
       # instead of the string... this is faster if you're going
       # to use the sql over and over.  Returns a t/f like you'd
       # expect.  (i.e. $dbo->do("stuff") or die $dbo->errstr);

   $dbo->lock("table1", "table2", "table3");
       # MySQL::Easy uses only write locks.  Those are the ones
       # where nobody can read or write to the table except the
       # locking thread.  If you need a read lock, let Jet know.
       # Most probably though, if you're using this, it's a
       # smaller app, and it doesn't matter anyway.
   $dbo->unlock;

   $sth = $dbo->ready("Sql Sql Sql=? and Sql=?");
       # returns a DBI statement handle...
       # $sth->execute($bindvar); $sth->fetchrow_hashref; etc...

   $arr = $dbo->firstcol("select col from tab where x=? and y=?", $x, $y)
       # returns an arrayref of values for the sql.
       # You know, print "val: $_\n" for @$arr;
       # very handy...

   $id = $dbo->last_insert_id;
       # self explainatory?

   $dbo->trace(1); $dbo->do("sql"); $dbo->trace(0);
       # turns the DBI trace on and off.

   $dbo->errstr
       # returns an error string for the last error on the
       # thread...  Same as a $sth->errstr.  It's actually
       # described in DBI

   $dbo->check_warnings
       # I'll just give this example:
       $dbo->do("create temporary table cool( field enum('test1', 'test2') not null )");
       $dbo->do("insert into cool set field='test3'");
       $dbo->check_warnings 
           or die "SQL WARNING: $@\twhile inserting test field\n\t";

   $dbo->set_host($h); $dbo->set_port($p); 
   $dbo->set_user($U); $dbo->set_pass($p);
       # The first time you do a do/ready/firstcol/etc,
       # MySQL::Easy connects to the database.  You may use these
       # set functions to override values found in your ~/.my.cnf
       # for user and pass.  MySQL::Easy reads _only_ the user
       # and pass from that file.  The host name will default to
       # "localhost" unless explicitly set.  Also, it will die on
       # a fatal error if the user or pass is false and the
       # ~/.my.cnf cannot be opened.

   my $table;
   my $sth = $dbo->bind_execute("show tables", \( $table ) );
       # This was Josh's idea... And a good one.

   die $dbo->errstr unless $sth;  
       # bind_execute returns undef if either the bind
       # or execute phases fail.

   print "$table\n" while fetch $sth;

   # Anything from the DBI.pm manpage will work with the
   # $dbo (thanks to an AUTOLOAD function).

=head1 AUTHOR

Paul Miller <jettero@cpan.org>

I am using this software in my own projects...  If you find bugs, please please
please let me know. :)

Actually, let me know if you find it handy at all.  Half the fun of releasing
this stuff is knowing that people use it.

=head1 THANKS

For bugs and ideas: Josh Rabinowitz <joshr-cpan@joshr.com>

=head1 COPYRIGHT

GPL!  I included a gpl.txt for your reading enjoyment.

Though, additionally, I will say that I'll be tickled if you were to include
this package in any commercial endeavor.  Also, any thoughts to the effect that
using this module will somehow make your commercial package GPL should be
washed away.

I hereby release you from any such silly conditions.

This package and any modifications you make to it must remain GPL.  Any
programs you (or your company) write shall remain yours (and under whatever
copyright you choose) even if you use this package's intended and/or exported
interfaces in them.

=head1 SEE ALSO

perl(1), DBI(3)

=cut
