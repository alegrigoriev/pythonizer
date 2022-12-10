# issue s195 - Naming a variable $caller generates incorrect code
use Carp::Assert;

my @tmp = caller();     # Causes the problem
my $caller = 1;
my $tot = 0;
while (my $package = caller($caller++)) {
    $tot++;
}
assert($tot == 0);

print "$0 - test passed\n";
