# issue s332 - Implement use warnings FATAL => qw(numeric);
use strict;
use warnings FATAL => qw(numeric);

use Carp::Assert;

sub perform_operation {
    my ($input, $operation) = @_;

    my $result = eval {
        if ($operation eq 'number') {
            return 0 + $input;
        } elsif ($operation eq 'int') {
            return int($input);
        } elsif ($operation eq 'float') {
            return $input + 0.0;
        } elsif ($operation eq 'non-fatal-number') {
            { use warnings NONFATAL => 'numeric';
              print STDERR "Warning is expected: ";
              return 0 + $input;
            }
        } elsif ($operation eq 'no-warn-number') {
            { no warnings 'numeric';
              return 0 + $input;
            }
        } else {
            die "Unsupported operation: $operation";
        }
    };

    return $@ ? $@ : $result;
}

# Test cases
my @test_cases = (
    {
        description => 'Test non-numeric string in numeric operation',
        input       => 'abc',
        operation   => 'number',
        expected_error_substr => "isn't numeric in",
    },
    {
        description => 'Test numeric string in numeric operation',
        input       => '123',
        operation   => 'number',
        expected => 123,
    },
    {
        description => 'Test non-numeric string in non-fatal numeric operation',
        input       => 'abc',
        operation   => 'non-fatal-number',
        expected => 0,
    },
    {
        description => 'Test non-numeric string in no warnings numeric operation',
        input       => 'abc',
        operation   => 'no-warn-number',
        expected => 0,
    },
    {
        description => 'Test non-numeric string in int operation',
        input       => 'abc',
        operation   => 'int',
        expected_error_substr => "isn't numeric in",
    },
    {
        description => 'Test numeric string in int operation',
        input       => '3.2',
        operation   => 'int',
        expected => 3,
    },
    {
        description => 'Test non-numeric string in float operation',
        input       => 'abc',
        operation   => 'float',
        expected_error_substr => "isn't numeric in",
    },
    {
        description => 'Test numeric string in float operation',
        input       => '3.2',
        operation   => 'float',
        expected => 3.2,
    },
);

for my $test (@test_cases) {
    #print "Running test: $test->{description}\n";
    my $result = perform_operation($test->{input}, $test->{operation});
    if (defined $test->{expected_error_substr}) {
        assert(index($result, $test->{expected_error_substr}) != -1, "$test->{description}, expected_substr=$test->{expected_error_substr}, result=$result");
    } else {
        assert((defined($result) && defined($test->{expected}) && $result == $test->{expected}) ||
           (!defined($result) && !defined($test->{expected})),
           "$test->{description}, expected=$test->{expected}, result=$result");
    }
    #print "Test passed: $test->{description}\n\n";
}

print "$0 - test passed!\n";

