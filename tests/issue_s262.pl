# issue s262 - map that updates a variable in the function generates incorrect code
use Carp::Assert;
no warnings 'experimental';

my @keys = ('k1', 'k2', 'k3');

my $cnt = 0;
my %ndx_map = map {$_ => $cnt++} @keys;

assert(%ndx_map ~~ {k1=>0, k2=>1, k3=>2});

print "$0 - test passed!\n";
