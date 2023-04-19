# issue s333 - @$fbav = (undef) x $value; generates bad code
use strict;
use warnings;
no warnings 'experimental';
use Carp::Assert;

sub resize_array {
    my ($fbav, $value) = @_;

    assert(ref($fbav) eq 'ARRAY', 'First argument must be an array reference');
    assert(defined($value) && $value =~ /^\d+$/, 'Second argument must be a non-negative integer');

    @$fbav = (undef) x $value if @$fbav != $value;

    return $fbav;
}

sub test_resize_array {
    my ($array_ref, $value, $expected_result) = @_;

    my $result = resize_array($array_ref, $value);

    if (ref($result) eq ref($expected_result) && $result ~~ $expected_result) {
        #print "Test passed: resize_array for array with " . scalar(@$array_ref) . " elements to size $value\n";
        ;
    } else {
        assert(0,  "Test failed: resize_array for array with " . scalar(@$array_ref) . " elements to size $value\n");
    }
}

# Test case 0: array (not arrayref)
{
    my $value = 4;
    my @fb = (undef) x $value;
    assert(scalar(@fb) == 4, "Wrong size of fb");
    for(my $i = 0; $i < @fb; $i++) {
        assert(!defined $fb[$i]);
    }
}

# Test case 1: Resize empty array to non-zero length
{
    my $array_ref = [];
    my $value = 5;
    # Don't use the same expr in the test my $expected_result = [(undef) x $value];
    my $expected_result = [];
    for(my $i = 0; $i < $value; $i++) {
        push @$expected_result, undef;
    }
    test_resize_array($array_ref, $value, $expected_result);
}

# Test case 2: Resize array with elements to a smaller size
{
    my $array_ref = [1, 2, 3, 4, 5];
    my $value = 3;
    # Don't use the same expr in the test my $expected_result = [(undef) x $value];
    my $expected_result = [];
    for(my $i = 0; $i < $value; $i++) {
        push @$expected_result, undef;
    }
    test_resize_array($array_ref, $value, $expected_result);
}

# Test case 3: Resize array with elements to a larger size

{
    my $array_ref = [1, 2, 3];
    my $value = 6;
    # Don't use the same expr in the test my $expected_result = [(undef) x $value];
    my $expected_result = [];
    for(my $i = 0; $i < $value; $i++) {
        push @$expected_result, undef;
    }
    test_resize_array($array_ref, $value, $expected_result);
}

# Test case 4: Resize array to the same size

{
    my $array_ref = [1, 2, 3, 4];
    my $value = 4;
    my $expected_result = [1, 2, 3, 4];
    test_resize_array($array_ref, $value, $expected_result);
}

# Test case 5: Resize empty array to zero length

{
    my $array_ref = [];
    my $value = 0;
    my $expected_result = [];
    test_resize_array($array_ref, $value, $expected_result);
}

# Test case 6: Resize array with elements to zero length

{
    my $array_ref = [1, 2, 3, 4, 5];
    my $value = 0;
    my $expected_result = [];
    test_resize_array($array_ref, $value, $expected_result);
}

print "$0 - test passed!\n";
