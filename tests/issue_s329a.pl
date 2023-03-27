# issue s329a - $var = eval {...} or $^W && warn $@; generates bad code - test case 2

use strict;

use Carp::Assert;

sub evaluate_code {
    my ($input) = @_;

    my $var = eval { 
        use warnings FATAL => qw(numeric);

        my $result = $input ** 2;
        return $result;
    } or $^W && warn $@;
    return $var;
}

# Test cases
my @test_cases = (
    {
        description => 'Test with a valid number',
        input       => 4,
        expected    => 16,
    },
    {
        description => 'Test with a non-numeric string',
        input       => 'abc',
        expected    => undef,
    },
    {
        description => 'Test with a negative number',
        input       => -3,
        expected    => 9,
    },
);

for my $test (@test_cases) {
    #print "Running test: $test->{description}\n";
    my $result = evaluate_code($test->{input});
    assert((defined($result) && defined($test->{expected}) && $result == $test->{expected}) ||
           (!defined($result) && !defined($test->{expected})),
           $test->{description});
       #print "Test passed: $test->{description}\n\n";
}

print "$0 - test passed!\n";

