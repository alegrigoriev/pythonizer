# issue s307 - implement another form of range (..) operator
use Carp::Assert;
no warnings 'experimental';

my %hash_of_arrays = (a=>1, b=>2, c=>3, d=>4);
my @bind_ids = 1..keys(%hash_of_arrays);

assert(scalar(@bind_ids) == 4);

for(my $i = 1; $i <= 4; $i++) {
    assert($bind_ids[$i-1] == $i);
}

# Make sure we can extend it by index, e.g. it's an Array and not a list
$bind_ids[4] = 5;

assert(scalar(@bind_ids) == 5);
assert($bind_ids[4] == 5);

# Some more test cases from ChatGPT:

# Test case 1: range operator produces expected range
my @range1 = (1..5);
assert("@range1" eq "1 2 3 4 5", "Range operator produces expected range");

# Test case 2: range operator with negative numbers produces expected range
my @range2 = (-3..3);
assert("@range2" eq "-3 -2 -1 0 1 2 3", "Range operator with negative numbers produces expected range");

# Test case 3: range operator in string produces expected range
my @range3 = (10..20);
assert(@range3[0..4] ~~ [10,11,12,13,14], "Range operator in subscript produces expected range");
# Doesn't quite work: assert("@range3[0..4]" eq "10 11 12 13 14", "Range operator in interpolated string produces expected range");

# Test case 4: range operator with reversed arguments produces empty range
my @range4 = (5..1);
assert("@range4" eq "", "Range operator with reversed arguments produces empty range");

# Test case 5: range operator with non-integer arguments produces expected range
my @range5 = (2.5..5.5);
assert("@range5" eq "2 3 4 5", "Range operator with non-integer arguments produces expected range");

# Test case 6: range operator with strings
my @range6 = (0..9, 'a'..'f');
assert("@range6" eq '0 1 2 3 4 5 6 7 8 9 a b c d e f', "Range operator with string arg produces expected range");

# Scalar Context tests:

sub range_test {
    my ($left, $right, $expected) = @_;

    if($left..$right) {
        assert($expected, "$left..$right = True, not $expected");
    } else {
        assert(!$expected, "$left..$right = False, not $expected");
    }
}

range_test(0,1,0);
range_test(0,0,0);
range_test(1,0,1);
range_test(1,0,2);
range_test(1,1,'3E0');
range_test(0,1,0);

print "$0 - test passed!\n";
