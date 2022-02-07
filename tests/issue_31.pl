# issue 31 - Array assignment generated bad python copy code

use Carp::Assert;

my @arr1 = (4, 3, 2);

my @arr2 = @arr1;

assert(@arr1 == 3);
assert(3 == @arr2);
assert($arr1[0] == $arr2[0]);
assert($arr1[1] == $arr2[1]);
assert($arr1[2] == $arr2[2]);
$arr2[0] = 14;
assert($arr1[0] == 4);
assert($arr2[0] == 14);

print "$0 - test passed!\n";

