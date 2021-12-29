# issue 23: Float constants that start with a '.' or have an E are not handled
use Carp::Assert;
$i = .25;
assert($i == 0.25);
assert($i == 25e-2);
assert($i == 2.5e-1);
assert($i == 0.25E00);
assert($i == .25E00);

$j = -.5;
assert($j == -0.5);
assert($j == -50e-2);
assert($j == -5.0e-1);
assert($j == -0.5E00);
assert($j == -.5E00);

print "$0 - test passed!\n";
