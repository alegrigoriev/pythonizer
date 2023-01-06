# issue s237 - implement xor operator
use Carp::Assert;
use List::Util qw(max);

# Test that xor returns true when one and only one of its operands is true
assert(1 xor 0);
assert(0 xor 1);
assert(!(1 xor 1));
assert(!(0 xor 0));

# Test that xor works with more complex expressions as operands
assert((1+1 == 2) xor (2*2 == 5));
assert((1+1 == 2) xor (2*2 == 5));
assert(!((1+1 == 2) xor (2*2 == 4)));

# Test that xor has the correct precedence
assert(1 xor 0 && 0);
assert(1 xor 0 and 0);
assert(0 and 1 xor 1);
assert(1 xor 1 xor 1);

# Test with scalars stored in hashes
%hash1 = (a => 1, b => 0);
%hash2 = (a => 0, b => 1);
assert($hash1{a} xor $hash2{a});
assert($hash1{b} xor $hash2{b});
assert(!($hash1{a} xor $hash1{a}));

# Test with scalars stored in arrays
@array1 = (1, 0);
@array2 = (0, 1);
assert($array1[0] xor $array2[0]);
assert($array1[1] xor $array2[1]);
assert(!($array1[0] xor $array1[0]));

# Test with non-binary values
assert(!(2 xor 3));
assert(!(3 xor 2));
assert(2 xor 0);
assert(0 xor 3);
assert(!(2 xor 2));
assert(!(3 xor 3));

package SomeClass;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub some_method {
    my $self = shift;
    my $arg1 = shift;
    my $arg2 = shift;
    # Do something with $arg1 and $arg2
    return 0;  # Example return value
}

1;  # Required for all perl modules

package main;

use Carp::Assert;

# Test with sub call
sub test_sub {
    my ($arg1, $arg2) = @_;

    assert(!defined $arg1 || $arg1 == 2);
    assert(!defined $arg2 || $arg2 == 3);
    return 0;
}
assert(test_sub() xor 3);
assert(3 xor test_sub());
assert(!(test_sub() xor test_sub()));

# Test with function call
assert(max(2, 3) xor 0);
assert(0 xor max(2, 3));
assert(!(max(2, 3) xor max(2, 3)));

# Test with method call
$obj = SomeClass->new();
assert($obj->some_method() xor 3);
assert(3 xor $obj->some_method());
assert(!($obj->some_method() xor $obj->some_method()));

# Test with method call with arguments
assert($obj->some_method(2, 3) xor 3);
assert(3 xor $obj->some_method(2, 3));
assert(!($obj->some_method(2, 3) xor $obj->some_method(2, 3)));

# Test with sub call

assert(test_sub xor 3);
assert(3 xor test_sub);
assert(!(test_sub xor test_sub));

assert(test_sub 2, 3 xor 3);
assert(3 xor test_sub 2, 3);
assert(!(test_sub 2, 3 xor test_sub 2, 3));

# Test with function call
assert(max 2, 3 xor 0);
assert(0 xor max 2, 3);
assert(!(max 2, 3 xor max 2, 3));

# Test with method call
$obj = SomeClass->new;
assert($obj->some_method xor 3);
assert(3 xor $obj->some_method);
assert(!($obj->some_method xor $obj->some_method));

print "$0 - test passed!\n";
