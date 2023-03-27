# issue s329: $var = eval {...} or $^W && warn $@; generates bad code
use strict;
use warnings;

use Carp::Assert;

sub evaluate_code {
    my ($input) = @_;

    my $var = eval { my $result = 10 / $input;
                     return $result;
                   } or $^W && warn $@;
    return $var;
}

# Test cases
my @test_cases = (
    {
        description => 'Test with a valid number',
        input       => 5,
        expected    => 2,
    },
    {
        description => 'Test with zero causing a division by zero error',
        input       => 0,
        expected    => undef,
    },
    {
        description => 'Test with a negative number',
        input       => -2,
        expected    => -5,
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

