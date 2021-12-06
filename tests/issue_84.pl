# issue 84: choosing multiple elements from array
use Carp::Assert;
@arr = (0,1,2,3,4);
($z, $o, $f) = @arr[0, 1, 4];
assert($z == 0 && $o == 1 && $f == 4);
print "$0 - test passed!\n";
