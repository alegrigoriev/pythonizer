# issue s221 - Hash keys with -X are incorrectly being translated as file test operations
use Carp::Assert;

my %test_hash = (-a => 1, -b => 2, -c => 3, -d => 4);

@keys = sort keys %test_hash;

assert(join(' ', @keys) eq '-a -b -c -d');

print "$0 - test passed!\n";
