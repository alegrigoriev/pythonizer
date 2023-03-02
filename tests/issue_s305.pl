# issue s305 - calling keys (or values) on a hash should reset the 'each' iterator
use Carp::Assert;

my %hash = (
    a => 1,
    b => 2,
    c => 3,
);

my %seen;
my ($k1, $v1) = each %hash;
my ($k2, $v2) = each %hash;
assert($v1 == $hash{$k1});
assert($v2 == $hash{$k2});
my @keys = keys %hash;      # Resets the iterator
my ($k3, $v3) = each %hash;
my ($k4, $v4) = each %hash;
my ($k5, $v5) = each %hash;
$seen{$k3} = $v3;
$seen{$k4} = $v4;
$seen{$k5} = $v5;
assert(scalar(%seen) == 3);

assert((grep { $_ eq $k3 } @keys) && $v3 == $hash{$k3});
assert((grep { $_ eq $k4 } @keys) && $v4 == $hash{$k4});
assert((grep { $_ eq $k5 } @keys) && $v5 == $hash{$k5});

# Test the self-reset after running out of keys
my ($k6, $v6) = each %hash;
assert(!defined $k6 && !defined $v6);

my ($k7, $v7) = each %hash;
assert((grep { $_ eq $k7 } @keys) && $v7 == $hash{$k7});

# Now reset it using 'values'
values %hash;
my $cnt = 0;
while(my ($key, $value) = each %hash) {
    $cnt++;
    assert((grep { $_ eq $key } @keys) && $value == $hash{$key});
}
assert($cnt == scalar(@keys));

print "$0 - test passed!\n";
