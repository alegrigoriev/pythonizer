# issues found trying to convert Complex.pm to python
package Math::Complex;
use Carp::Assert;

# issue ||= not implemented

$val = 7;
$val ||= 1;
assert($val == 7);

$val = 0;
$val ||= 1;
assert($val == 1);

# issue: assignment with multiple ? : operators generates bad code
sub _stringify_cartesian {
        my $z  = shift;
	my ($x, $y) = @{$z->{_cartesian}};
	my ($re, $im);

	my $format = $z->{display_format};
	my $format = $format->{format};

		    $im =
			defined $format ?
			    sprintf($format, $y) :
			    ($y == 1 ? "" : ($y == -1 ? "-" : $y));

	return $im;
}

my $z1 = {_cartesian=>[0,-1], display_format=>{format=>'%f'}};
my $result = _stringify_cartesian($z1);
assert($result eq '-1.000000');

my $z2 = {_cartesian=>[0,1], display_format=>{format=>'%f'}};
$result = _stringify_cartesian($z2);
assert($result eq '1.000000');

my $z3 = {_cartesian=>[0,-1], display_format=>{format=>undef}};
$result = _stringify_cartesian($z3);
assert($result eq '-');

my $z4 = {_cartesian=>[0,1], display_format=>{format=>undef}};
$result = _stringify_cartesian($z4);
assert($result eq '');

# issue: testing if argument is defined doesn't work as expected

sub _logofzero {
	my $zero = 0;
	if (defined $_[1]) {
		return 2;
	}
	if (defined $_[$zero]) {	# test varargs too
		return 1;
	}
	return 0;
}

assert(_logofzero() == 0);
assert(_logofzero(1) == 1);
assert(_logofzero(1,2) == 2);
assert(_logofzero(1,undef) == 1);

# Now try a normal array
my @arr = (1,2,3);
assert(defined $arr[2]);
assert(!defined $arr[3]);
$arr[4] = 0;
assert(!defined $arr[3]);
assert(defined $arr[4]);
assert(!defined $arr[7]);

# issue: Calls to cos and sin aren't converting string args to num

sub _update_cartesian {
	my $self = shift;
	my ($r, $t) = @{$self->{'polar'}};
	$self->{c_dirty} = 0;
	return $self->{'cartesian'} = [$r * CORE::cos($t), $r * CORE::sin($t)];
}

my $self = {polar=>['1.0', '0.0']};
my $cart = _update_cartesian($self);
assert($self->{c_dirty} == 0);
assert($self->{cartesian}->[0] == 1.0);
assert($self->{cartesian}->[1] == 0.0);
assert($cart->[0] == 1.0);
assert($cart->[1] == 0.0);

# issue calling with @_ needs to splat the args

sub cosech { Math::Complex::csch(@_) }

sub csch {
	return $_[0];
}

assert(csch(4) == 4);
assert(cosech(5) == 5);

# issue - flags on qr get lost if used as part of a larger pattern and need to be built in using (?flags:regex)

my $gre = qr'\s*([\+\-]?(?:(?:(?:\d+(?:_\d+)*(?:\.\d*(?:_\d+)*)?|\.\d+(?:_\d+)*)(?:[eE][\+\-]?\d+(?:_\d+)*)?))|inf)'i;

assert('INF' =~ $gre);
assert('INF' =~ /^$gre$/);

# issue: var used in re.sub not being converted to str


sub _emake {
    my $arg = shift;
    my ($p, $q);

    if ($arg =~ /^\s*\[\s*$gre\s*(?:,\s*$gre\s*)?\]\s*$/) {
	($p, $q) = ($1, $2 || 0);
    } elsif ($arg =~ /^\s*$gre\s*$/) {
	($p, $q) = ($1, 0);
    }
    if (defined $p) {
	$p =~ s/^\+//;
	$q =~ s/^\+//;		# Error on this line
	$p =~ s/^(-?)inf$/"${1}9**9**9"/e if $has_inf;	# This doesn't work either!
	$q =~ s/^(-?)inf$/"${1}9**9**9"/e if $has_inf;
    }

    return ($p, $q);
}

my @c0 = _emake('2.0');		# should match second regex
assert($c0[0] == 2.0 && $c0[1] == 0.0);

# issue - 'e' eval on s///e not working if stmt has modifier

my $i = 0;
$i =~ s/0/chr 0x34/e if $i == 1;
assert($i == 0);
$i =~ s/(0)/(chr 0x34).$1/e if $i == 0;
assert($i == 40);
$i =~ s/4/5/e if $i == 40;
assert($i == 50);

# issue: multi-assignment stmt not working properly

my %LOGN;
sub logn {
	my ($z, $n) = @_;
	#$z = cplx($z, 0) unless ref $z;
	my $logn = $LOGN{$n};
	$logn = $LOGN{$n} = CORE::log($n) unless defined $logn;	# Cache log(n)
	#return &log($z) / $logn;
	return log($z) / $logn;
}

my $eps = 1e-14;
my $l100 = logn(100, 10);
assert(abs($l100 - 2.0) < $eps);
assert(exists $LOGN{10});


# issue - 'my' declared in comma operator on for stmt being ignored
# issue - push of ? : operator generates incorrect code

$theta = 42;
sub root {
    my ($t, $n, $theta_inc) = @_;

    my @root;
    my $zero = 0;
    for (my $i = 0, my $theta = $t / $n;
		 $i < $n;
		 $i++, $theta += $theta_inc) {
	push @root, $zero ? $zero : $theta;
    }
    return @root;
}
my @ans = root(12, 2, 1);
assert(@ans == 2 && $ans[0] == 6 && $ans[1] == 7);
assert($theta == 42);


# issue - need to implement wantarray

sub needs_to_know {
	return wantarray ? (1, 2, 3) : 1;
}

assert(needs_to_know() == 1);	# scalar context
my @ntk = needs_to_know();
assert(@ntk == 3 && join('', @ntk) == '123');

sub check_wantarray_overload {
	my $wantarray = 0;
	return wantarray ? (2,3) : $wantarray;
}
assert(check_wantarray_overload() == 0);
@ntk = check_wantarray_overload();
assert(join('', @ntk) == '23');

print "$0 - test passed!\n";
