# issue s93: Setting array last index as the only reference doesn't generate code to initialize the array
use Carp::Assert;

$#myArray = -1;
assert(scalar(@myA) == 0);
assert($#myB == -1);
$#myC += 1;
$#myD++;

print "$0 - test passed!\n";
