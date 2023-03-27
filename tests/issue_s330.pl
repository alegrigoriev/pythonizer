# issue s330 - Implement use overload int
use strict;
use warnings;
use Carp::Assert;
use lib '.';
use MyInt;

# Test basic usage
my $a = MyInt->new(5);
assert(defined $a, 'Object creation successful');
assert(int($a) == 5, 'int() with positive integer works');

# Test negative integer
my $b = MyInt->new(-5);
assert(int($b) == -5, 'int() with negative integer works');

# Test zero
my $c = MyInt->new(0);
assert(int($c) == 0, 'int() with zero works');

# Test edge case: largest positive integer
my $d = MyInt->new(2**31 - 1);
assert(int($d) == 2**31 - 1, 'int() with largest positive integer works');

# Test edge case: smallest negative integer
my $e = MyInt->new(-(2**31));
assert(int($e) == -(2**31), 'int() with smallest negative integer works');

# Test error handling
eval { MyInt->new(undef) };
assert($@, 'Error thrown when value is undef');

eval { MyInt->new('abc') };
assert($@, 'Error thrown when value is not an integer');

eval { MyInt->new(3.14) };
assert($@, 'Error thrown when value is a float');

print "$0 - test passed!\n";

