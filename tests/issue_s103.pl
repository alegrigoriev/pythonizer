# issue s103 - referencing the default variable without setting it causes an error
use Carp::Assert;

chomp;

assert($_ eq '');
print "$0 - test passed\n";
