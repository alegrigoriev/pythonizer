# issue 105 - Assignment generates bad code if there are any ":=" operators in the LHS

use Carp::Assert;

my (@arr, $i);
$arr[$i=0] = 42;

assert($i == 0);
assert($arr[0] == 42);
assert(@arr == 1);

print "$0 - test passed!\n";
