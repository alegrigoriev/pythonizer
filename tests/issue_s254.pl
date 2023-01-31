# issue s254 - Empty list in scalar context should be changed to undef
# Written (mostly) by chatGPT
use Carp::Assert;

sub empty {
  return ();
}

sub empty_implicit_return { () }

sub empty_conditional_return { 
    return () if 1==1;
}

sub empty_wantarray_return {
    return wantarray ? () : undef;
}

sub empty_array {
    my @array = ();
    return @array;
}

# Check if the empty subroutine returns undef
assert(not defined(empty()));

# Check if the empty subroutine returns an empty list
assert(not scalar(empty()));

# Check if the empty subroutine returns the correct value when called in list context
my @result = empty();
assert(scalar(@result) == 0);

# Check if the empty subroutine returns the correct value when called in list context - with implicit return
@result = empty_implicit_return();
assert(scalar(@result) == 0);

# Check if the empty subroutine returns the correct value when called in list context - with conditional return
@result = empty_conditional_return();
assert(scalar(@result) == 0);

# Check if the empty subroutine returns the correct value when called in list context - with wantarray return
@result = empty_wantarray_return();
assert(scalar(@result) == 0);

# Check if the empty subroutine returns the correct value when called in scalar context
my $result = empty();
assert(not defined($result));

# Check if the empty subroutine returns the correct value when called in scalar context - with implicit return
$result = empty_implicit_return();
assert(not defined($result));

# Check if the empty subroutine returns the correct value when called in scalar context - with conditional return
$result = empty_conditional_return();
assert(not defined($result));

# Check if the empty subroutine returns the correct value when called in scalar context - with wantarray return
$result = empty_wantarray_return();
assert(not defined($result));

# Check if the empty subroutine returns the correct value when called in scalar context - with 'scalar'
$result = scalar empty();
assert(not defined($result));

# Check if () is defined list
assert(!defined scalar(()));

# Check if () is an empty list
#assert(scalar(()) == 0);

# Check if an array assigned by () works the same way (it doesn't)

my @array = ();
my $scalar = @array;
assert(defined $scalar && $scalar == 0);

$scalar = scalar @array;
assert(defined $scalar && $scalar == 0);

# Check direct assignment of () to a scalar

$scalar = ();
assert(!defined $scalar);

# Check using the scalar function on ()
$scalar = scalar(());
assert(!defined $scalar);

# Check a sub that returns an empty array gives 0 not undef
# We don't support assigning an array coming back from a sub to
# a scalar else we have to check every sub call or add wantarray
# to every sub that can return an array!
#$scalar = empty_array();
#assert(defined $scalar && $scalar == 0);

print "$0 - test passed!\n";
