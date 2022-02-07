# issue 29 - Pre-increment as a statement doesn't generate proper code
use Carp::Assert;

++$i;
assert($i == 1);
$i++;
assert($i == 2);
--$i;
assert($i == 1);
$i--;
assert($i == 0);

print "$0 - test passed!\n";
