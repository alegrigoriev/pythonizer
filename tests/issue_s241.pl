# issue s241 - Wantarray and other sub options need to be inherited, nested sub levels not properly maintained
use Carp::Assert;
my %subst;  # compiled encoding regexps

sub encode_entities
{
    return undef unless defined $_[0];
    # SNOOPYJC my $ref;
    # SNOOPYJC if (defined wantarray) {
    # SNOOPYJC my $x = $_[0];
    # SNOOPYJC $ref = \$x;     # copy
    # SNOOPYJC } else {
    # SNOOPYJC $ref = \$_[0];  # modify in-place
    # SNOOPYJC }
    my $arg = $_[0];        # SNOOPYJC
    if (defined $_[1] and length $_[1]) {
	  unless (exists $subst{$_[1]}) {
	    # Because we can't compile regex we fake it with a cached sub
	    my $chars = $_[1];
	    $chars =~ s,(?<!\\)([]/]),\\$1,g;
	    $chars =~ s,(?<!\\)\\\z,\\\\,;
        $subst{$_[1]} = sub {
                                my $arg = $_[0];
                                $arg =~ s/([$chars])/$char2entity{$1} || num_entity($1)/ge; 
                                return $arg;
                            };   # SNOOPYJC
	  }
      # SNOOPYJC &{$subst{$_[1]}}($$ref);
	  $result = &{$subst{$_[1]}}($arg);
    } else {
	  # Encode control chars, high bit chars and '<', '&', '>', ''' and '"'
      $result = $arg;
	  $result =~ s/([^\n\r\t !\#\$%\(-;=?-~])/$char2entity{$1} || num_entity($1)/ge;
    }
    if(!defined wantarray) {        # SNOOPYJC
        $_[0] = $result;            # SNOOPYJC: Change the argument
    }                               # SNOOPYJC
    return $result;                 # SNOOPYJC
    # SNOOPYJC $$ref;
}

sub num_entity {
    sprintf "&#x%X;", ord($_[0]);
}

# 3 ways a sub should inherit the attributes of the sub it's transfering control to:

sub encode_entities_numeric {
    local %char2entity;
    return &encode_entities;   # a goto &encode_entities wouldn't work (it loses the locals)
}

sub alias_encode_entities {
    goto &encode_entities;
}

*ee = \&encode_entities;

%char2entity = ('&' => '&amp;');

my $string = 'ab&c<';

$encoded = encode_entities($string);
$expected = 'ab&amp;c&#x3C;';
assert($encoded eq $expected, "1st test failed: $encoded vs $expected");
assert($string eq 'ab&c<', "1st test incorrectly modified string: $string");

$encoded = encode_entities($string, '&');
$expected = 'ab&amp;c<';
assert($encoded eq $expected, "2nd test failed: $encoded vs $expected");
assert($string eq 'ab&c<', "2nd test incorrectly modified string: $string");

encode_entities($string);
$expected = 'ab&amp;c&#x3C;';
assert($string eq $expected, "3rd test failed: $string vs $expected");

$string = 'ab&c<';

$encoded = alias_encode_entities($string);
$expected = 'ab&amp;c&#x3C;';
assert($encoded eq $expected, "1st alias test failed: $encoded vs $expected");
assert($string eq 'ab&c<', "1st alias test incorrectly modified string: $string");

$encoded = alias_encode_entities($string, '&');
$expected = 'ab&amp;c<';
assert($encoded eq $expected, "2nd alias test failed: $encoded vs $expected");
assert($string eq 'ab&c<', "2nd alias test incorrectly modified string: $string");

alias_encode_entities($string);
$expected = 'ab&amp;c&#x3C;';
assert($string eq $expected, "3rd alias test failed: $string vs $expected");

$string = 'ab&c<';

$encoded = ee($string);
$expected = 'ab&amp;c&#x3C;';
assert($encoded eq $expected, "1st ee test failed: $encoded vs $expected");
assert($string eq 'ab&c<', "1st ee test incorrectly modified string: $string");

$encoded = ee($string, '&');
$expected = 'ab&amp;c<';
assert($encoded eq $expected, "2nd ee test failed: $encoded vs $expected");
assert($string eq 'ab&c<', "2nd ee test incorrectly modified string: $string");

ee($string);
$expected = 'ab&amp;c&#x3C;';
assert($string eq $expected, "3rd ee test failed: $string vs $expected");

# Try a constant string
$encoded = encode_entities('ab&c<', '&');
$expected = 'ab&amp;c<';
assert($encoded eq $expected, "4th test failed: $encoded vs $expected");

# Try the numeric encoder
$string = 'ab&c<';
$encoded = encode_entities_numeric($string);
$expected = 'ab&#x26;c&#x3C;';
assert($encoded eq $expected, "1st numeric test failed: $encoded vs $expected");
assert($string eq 'ab&c<', "1st numeric test incorrectly modified string: $string");

encode_entities_numeric($string);
$expected = 'ab&#x26;c&#x3C;';
assert($string eq $expected, "2nd numeric test failed: $string vs $expected");

# Another wantarray issue from CGI.pm:
package CGI;
use Carp::Assert;

our $DefaultClass = 'CGI';
our $Q;

sub new { bless {}, shift }

sub self_or_default {
    return @_ if defined($_[0]) && (!ref($_[0])) &&($_[0] eq 'CGI');
    unless (defined($_[0]) && 
	    (ref($_[0]) eq 'CGI' || UNIVERSAL::isa($_[0],'CGI')) # slightly optimized for common case
	    ) {
	$Q = $CGI::DefaultClass->new unless defined($Q);
	unshift(@_,$Q);
    }
    return wantarray ? @_ : $Q;
}

sub unescapeHTML {
    my ($self,$string) = CGI::self_or_default(@_);
    return $string;
}

my $obj = new CGI;

assert($obj->unescapeHTML('abc') eq 'abc');

# Yet another wantarray issue from CGI.pm:

my $LIST_CONTEXT_WARN =  1;
sub param {
    my ($self,@p) = self_or_default(@_);
    return $self->all_parameters unless @p;

    if ( wantarray && $LIST_CONTEXT_WARN == 1 ) {
		my ( $package, $filename, $line ) = caller;
		if ( $package ne 'CGI' ) {
			$LIST_CONTEXT_WARN++; # only warn once
			warn "CGI::param called in list context from $filename line $line, this can lead to vulnerabilities. "
				. 'See the warning in "Fetching the value or values of a single named parameter"';
            assert(0, "We should not be calling warn, package should be 'CGI' but is $package");
		}
	}
    return if $p[0] ne 'foo';
    @result = ('param');
    return wantarray ?  @result : $result[0]
}

sub all_parameters {
    my $self = shift;
    return () unless defined($self) && $self->{'.parameters'};
    return () unless @{$self->{'.parameters'}};
    return @{$self->{'.parameters'}};
}

# List context
my @params = $obj->param;
assert(scalar(@params) == 0);

for my $param ($obj->param) {
    assert(0, "Shouldn't be any params but we have $param!");
}

@params = $obj->param('foo');
assert(scalar(@params) == 1 && $params[0] eq 'param');

@params = $obj->param('bar');
assert(scalar(@params) == 0);
for my $param ($obj->param('bar')) {
    assert(0, "for \$obj->param('bar'), shouldn't be any params but we have $param!");
}

# Scalar context
my $param = $obj->param;
assert(!defined $param);
$param = $obj->param('foo');
assert($param eq 'param');
$param = $obj->param('bar');
assert(!defined $param);

print "$0 - test passed!\n";
