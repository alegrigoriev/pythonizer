# @X = (split /regex/, $x) generates incorrect code
use Carp::Assert;

$x = "a,b";
@X = (split /,/, $x);
assert(@X == 2 && $X[0] eq 'a' && $X[1] eq 'b');

print "$0 - test passed!\n";
