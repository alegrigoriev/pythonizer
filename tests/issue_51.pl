# Escaped interpolation symbols in "..." generate incorrect code
use Carp::Assert;

$s1 = "\@notarr\$notscalar\"notquote\\";
assert($s1 eq '@notarr$notscalar"notquote\\');
$i = 1;
$s2 = "{bracketed}$i";
assert($s2 eq '{bracketed}1');
print "$0 - test passed!\n";
