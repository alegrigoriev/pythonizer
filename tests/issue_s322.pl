# issue s322 - Nested anonymous sub that contains a while loop with an array assignment can generate bad code
package DBI;

use strict;
use warnings;
use Carp::Assert;
use Carp;

#our $connect_via = 'connect';
our $dbi_debug = 0;
our %installed_drh = ();
our $errstr = '';

BEGIN {
    $ENV{DBI_DRIVER} = 'Mock';
}

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub install_driver {
    my ($class, $driver) = @_;
    my $drh = DBI->new;
    $installed_drh{$driver} = $drh;
    return $drh;
}

package DBI::db;

sub mock_connect {
    my ($drh, $dsn, $user, $pass, $attr) = @_;
    die "Invalid dsn $dsn" unless($dsn eq 'dbname=test_db;host=localhost');
    return bless {}, 'DBI::db';
}

sub connected {
    return 1;
}

package DBI;

our $connect_via = \&DBI::db::mock_connect;

sub default_user {
    my ($self, $user, $pass, $attr) = @_;
    return ($user || 'default_user', $pass || 'default_password');
}

sub _load_class {
    my ($class, $silent) = @_;
    return 1; # Return 1 to indicate successful class loading.
}

sub _set_isa {
    my ($classes, $parent) = @_;
    no strict 'refs';
    for my $class (@$classes) {
        push @{"${class}::ISA"}, $parent;
    }
}

sub _rebless {
    my ($obj, $class) = @_;
    bless $obj, $class . '::db';
}

sub connect {
    my $class = shift;
    my ($dsn, $user, $pass, $attr, $old_driver) = my @orig_args = @_;
    my $driver;

    if ($attr and !ref($attr)) { # switch $old_driver<->$attr if called in old style
	Carp::carp("DBI->connect using 'old-style' syntax is deprecated and will be an error in future versions");
        ($old_driver, $attr) = ($attr, $old_driver);
    }

    my $connect_meth = $attr->{dbi_connect_method};
    $connect_meth ||= $DBI::connect_via;	# fallback to default

    $dsn ||= $ENV{DBI_DSN} || $ENV{DBI_DBNAME} || '' unless $old_driver;

    if ($DBI::dbi_debug) {
	local $^W = 0;
	pop @_ if $connect_meth ne 'connect';
	my @args = @_; $args[2] = '****'; # hide password
	DBI->trace_msg("    -> $class->$connect_meth(".join(", ",@args).")\n");
    }
    Carp::croak('Usage: $class->connect([$dsn [,$user [,$passwd [,\%attr]]]])')
        if (ref $old_driver or ($attr and not ref $attr) or
            (ref $pass and not defined Scalar::Util::blessed($pass)));

    # extract dbi:driver prefix from $dsn into $1
    my $orig_dsn = $dsn;
    $dsn =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i
			or '' =~ /()/; # ensure $1 etc are empty if match fails
    my $driver_attrib_spec = $2 || '';

    # Set $driver. Old style driver, if specified, overrides new dsn style.
    $driver = $old_driver || $1 || $ENV{DBI_DRIVER}
	or Carp::croak("Can't connect to data source '$orig_dsn' "
            ."because I can't work out what driver to use "
            ."(it doesn't seem to contain a 'dbi:driver:' prefix "
            ."and the DBI_DRIVER env var is not set)");

    my $proxy;
    if ($ENV{DBI_AUTOPROXY} && $driver ne 'Proxy' && $driver ne 'Sponge' && $driver ne 'Switch') {
	my $dbi_autoproxy = $ENV{DBI_AUTOPROXY};
	$proxy = 'Proxy';
	if ($dbi_autoproxy =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i) {
	    $proxy = $1;
	    $driver_attrib_spec = join ",",
                ($driver_attrib_spec) ? $driver_attrib_spec : (),
                ($2                 ) ? $2                  : ();
	}
	$dsn = "$dbi_autoproxy;dsn=dbi:$driver:$dsn";
	$driver = $proxy;
	DBI->trace_msg("       DBI_AUTOPROXY: dbi:$driver($driver_attrib_spec):$dsn\n");
    }
    # avoid recursion if proxy calls DBI->connect itself
    local $ENV{DBI_AUTOPROXY} if $ENV{DBI_AUTOPROXY};

    my %attributes;	# take a copy we can delete from
    if ($old_driver) {
	%attributes = %$attr if $attr;
    }
    else {		# new-style connect so new default semantics
	%attributes = (
	    PrintError => 1,
	    AutoCommit => 1,
	    ref $attr           ? %$attr : (),
	    # attributes in DSN take precedence over \%attr connect parameter
	    $driver_attrib_spec ? (split /\s*=>?\s*|\s*,\s*/, $driver_attrib_spec, -1) : (),
	);
    }
    $attr = \%attributes; # now set $attr to refer to our local copy

    my $drh = $DBI::installed_drh{$driver} || $class->install_driver($driver)
	or die "panic: $class->install_driver($driver) failed";

    # attributes in DSN take precedence over \%attr connect parameter
    $user = $attr->{Username} if defined $attr->{Username};
    $pass = $attr->{Password} if defined $attr->{Password};
    delete $attr->{Password}; # always delete Password as closure stores it securely
    if ( !(defined $user && defined $pass) ) {
        ($user, $pass) = $drh->default_user($user, $pass, $attr);
    }
    $attr->{Username} = $user; # force the Username to be the actual one used

    my $connect_closure = sub {
	my ($old_dbh, $override_attr) = @_;

        #use Data::Dumper;
        #warn "connect_closure: ".Data::Dumper::Dumper([$attr,\%attributes, $override_attr]);

	my $dbh;
	unless ($dbh = $drh->$connect_meth($dsn, $user, $pass, $attr)) {
	    $user = '' if !defined $user;
	    $dsn = '' if !defined $dsn;
	    # $drh->errstr isn't safe here because $dbh->DESTROY may not have
	    # been called yet and so the dbh errstr would not have been copied
	    # up to the drh errstr. Certainly true for connect_cached!
	    my $errstr = $DBI::errstr;
            # Getting '(no error string)' here is a symptom of a ref loop
	    $errstr = '(no error string)' if !defined $errstr;
	    my $msg = "$class connect('$dsn','$user',...) failed: $errstr";
	    DBI->trace_msg("       $msg\n");
	    # XXX HandleWarn
	    unless ($attr->{HandleError} && $attr->{HandleError}->($msg, $drh, $dbh)) {
		Carp::croak($msg) if $attr->{RaiseError};
		Carp::carp ($msg) if $attr->{PrintError};
	    }
	    $! = 0; # for the daft people who do DBI->connect(...) || die "$!";
	    return $dbh; # normally undef, but HandleError could change it
	}

        # merge any attribute overrides but don't change $attr itself (for closure)
        my $apply = { ($override_attr) ? (%$attr, %$override_attr ) : %$attr };

        # handle basic RootClass subclassing:
        my $rebless_class = $apply->{RootClass} || ($class ne 'DBI' ? $class : '');
        if ($rebless_class) {
            no strict 'refs';
            if ($apply->{RootClass}) { # explicit attribute (ie not static method call class)
                delete $apply->{RootClass};
                DBI::_load_class($rebless_class, 0);
            }
            unless (@{"$rebless_class\::db::ISA"} && @{"$rebless_class\::st::ISA"}) {
                Carp::carp("DBI subclasses '$rebless_class\::db' and ::st are not setup, RootClass ignored");
                $rebless_class = undef;
                $class = 'DBI';
            }
            else {
                $dbh->{RootClass} = $rebless_class; # $dbh->STORE called via plain DBI::db
                DBI::_set_isa([$rebless_class], 'DBI');     # sets up both '::db' and '::st'
                DBI::_rebless($dbh, $rebless_class);        # appends '::db'
            }
        }

	if (%$apply) {

            if ($apply->{DbTypeSubclass}) {
                my $DbTypeSubclass = delete $apply->{DbTypeSubclass};
                DBI::_rebless_dbtype_subclass($dbh, $rebless_class||$class, $DbTypeSubclass);
            }
	    my $a;
	    foreach $a (qw(Profile RaiseError PrintError AutoCommit)) { # do these first
		    next unless  exists $apply->{$a};
		    $dbh->{$a} = delete $apply->{$a};
	    }
	    while ( my ($a, $v) = each %$apply) {
		        eval { $dbh->{$a} = $v }; # assign in void context to avoid re-FETCH
                warn $@ if $@;
	    }
	}

        # confirm to driver (ie if subclassed) that we've connected successfully
        # and finished the attribute setup. pass in the original arguments
	$dbh->connected(@orig_args); #if ref $dbh ne 'DBI::db' or $proxy;

	DBI->trace_msg("    <- connect= $dbh\n") if $DBI::dbi_debug & 0xF;

	return $dbh;
    };

    my $dbh = &$connect_closure(undef, undef);

    $dbh->{dbi_connect_closure} = $connect_closure if $dbh;

    return $dbh;
}

package main;

use strict;
use warnings;
use Carp::Assert;

# Test 1: Basic connect
{
    my $dsn = "dbi:Mock:dbname=test_db;host=localhost";
    my $dbh = DBI->connect($dsn, 'user', 'password', { RaiseError => 1 });
    assert(defined $dbh, 'Basic connect test failed');
}

# Test 2: Default username and password
{
    my $dsn = "dbi:Mock:dbname=test_db;host=localhost";
    my $dbh = DBI->connect($dsn, undef, undef, { RaiseError => 1 });
    assert(defined $dbh, 'Default username and password test failed');
    assert($dbh->{Username} eq 'default_user', 'Default username not set correctly');
}

# Test 3: Invalid DSN
{
    my $dsn = "invalid_dsn";
    eval {
        my $dbh = DBI->connect($dsn, 'user', 'password', { RaiseError => 1 });
    };
    assert($@, 'Invalid DSN test failed');
}

print "$0 - test passed!\n";
