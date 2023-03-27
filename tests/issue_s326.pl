# issue s326 - 
#!/usr/bin/perl
use strict;
use warnings;
use Carp::Assert;

# Function to test
sub stringify_hash {
    my ($hash_ref) = @_;
    return "@{[ %$hash_ref ]}";
}

# Test case
{
    my %test_hash = (
        key1 => 'value1',
    );
    my $expected_result = "key1 value1";

    my $result = stringify_hash(\%test_hash);
    my $test_result = ($result eq $expected_result);

    assert($test_result, "Test case for stringify_hash() failed");
    print "$0 - test passed!\n";
}

