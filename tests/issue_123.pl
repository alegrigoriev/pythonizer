# tr arguments should not be interpolated
use Carp::Assert;

$_ = 'abc';
$abc = 'def';
$def = 'abc';
tr/$abc/$def/;
assert($_ eq 'def');

print "$0 - test passed!\n";
