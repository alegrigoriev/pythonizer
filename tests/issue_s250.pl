# issue s250 - keys %{ ...} being translated as a mod operator
use Carp::Assert;

# Initialize the vhohash and vho1 variables
my %vhohash = (
    vho1 => {
        api1 => 'value1',
        api2 => 'value2',
        api3 => 'value3'
    },
    vho2 => {
        api4 => 'value4',
        api5 => 'value5',
        api6 => 'value6'
    }
);
my $vho1 = 'vho1';

# Count the number of keys in the hash
my $count_before = scalar keys %{ $vhohash{$vho1}};

# Initialize a counter
my $count = 0;

# Loop through the keys of the hash stored at the value of $vho1
foreach my $api1 (keys %{ $vhohash{$vho1}}) {
    # Test that the current key is valid
    assert(exists $vhohash{$vho1}{$api1}, "Error: Invalid key in vhohash");
    # Test that the value of the current key is not empty
    assert($vhohash{$vho1}{$api1} ne "", "Error: Empty value for key $api1");
    #print "$api1: $vhohash{$vho1}{$api1}\n";
    my $value = $vhohash{$vho1}{$api1};
    my $expected = $api1;
    $expected =~ s/api/value/;
    assert($value eq $expected, "Wrong value $value for key $api1 - should be $expected!");
    $count++;
}

# Count the number of keys processed by the loop
my $count_after = $count;

# Test that the loop processed the correct number of keys
assert($count_before == $count_after, "Error: Loop did not process the correct number of keys");

print "$0 - test passed!\n";
