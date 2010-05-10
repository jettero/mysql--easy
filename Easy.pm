
package MySQL::Easy::sth;

use Carp;
use common::sense;

our $AUTOLOAD;

# new {{{
sub new {
    my ($class, $mysql_e, $statement) = @_;
    my $this  = bless { s=>$statement, dbo=>$mysql_e }, $class;

    $this->{sth} = $this->{dbo}->handle->prepare( $statement );

    return $this;
}
# }}}
# bind_execute {{{
sub bind_execute {
    my $this = shift;

    $this->{sth}->execute;
    $this->{sth}->bind_columns( @_ );

    return $this;
}
# }}}
# AUTOLOAD {{{
sub AUTOLOAD {
    my $this = shift;
    my $sub  = $AUTOLOAD;
    my $wa   = wantarray;

    return unless $this->{sth};
    # croak "this sth is defunct.  please don't call things on it." unless $this->{sth};

    $sub = $1 if $sub =~ m/::(\w+)$/;

    my $tries = 2;
    if( $this->{sth}->can($sub) ) {
        my @ret;
        my $ret;
        my $warn;

        # warn "DEBUG: FYI, $$-$this is loading $sub()";

        EVAL_IT: eval {
            no strict 'refs';
            local $SIG{__WARN__} = sub { $warn = "@_"; };

            if( $wa ) {
                @ret = $this->{sth}->$sub( @_ );

            } else {
                $ret = $this->{sth}->$sub( @_ );
            }
        };

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

use Carp;
use common::sense;

use DBI;

our $AUTOLOAD;
our $VERSION = "2.1006";

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
    my $this = shift;

    $this = bless {}, $this;

    $this->{dbase} = shift; croak "dbase = '$this->{dbase}'?" unless $this->{dbase};
    $this->{dbh} = $this->{dbase} if ref($this->{dbase}) eq "DBI::db";

    my $args = shift;
    if( ref $args ) {
        for my $k (keys %$args) {
            my $f;

            if( $this->can($f = "set_$k") ) {
                $this->$f($args->{$k});

            } elsif( $k eq "trace" ) {
                $this->trace($args->{trace});

            } else {
                croak "unrecognized attribute: $k"
            }
        }

    } else {
        $this->trace($args);
    }

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
# firstval {{{
sub firstval {
    my $this = shift;
    my $query = shift;
    my $ar = $this->handle->selectcol_arrayref($query, undef, @_);
    return undef unless ref $ar;
    return $ar->[0];
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
    # return $this->handle->{mysql_insertid};
    return $this->handle->last_insert_id(undef,undef,undef,undef);
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

    $this->{dbh}->disconnect if $this->{dbh}; # curiously, sometimes we do have a handle, but the ping doesn't work
                                              # if we replace the handle, DBI complains about not disconnecting.
                                              # Heh.  It's gone dude, let it go.

    $this->{dbh} =
    DBI->connect("DBI:mysql:$this->{dbase}:host=$this->{host}:port=$this->{port}",
        $this->{user}, $this->{pass}, {

            RaiseError => ($this->{raise} ? 1:0),
            PrintError => ($this->{raise} ? 0:1),

            AutoCommit => 0,

            mysql_enable_utf8    => 1,
            mysql_compression    => 1,
            mysql_ssl            => 1,
            mysql_auto_reconnect => 1,

        });

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

sub set_raise {
    my $this = shift;

    $this->{raise} = shift;
}
# }}}
# bind_execute {{{
sub bind_execute {
    my $this = shift;
    my $sql  = shift;

    my $sth = $this->ready($sql);

    $sth->execute            or return;
    $sth->bind_columns( @_ ) or return;

    return $sth;
}
# }}}

1;
