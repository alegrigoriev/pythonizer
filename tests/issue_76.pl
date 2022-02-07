# issue 76 - substr with constant args generates incorrect code

use Carp::Assert;

$_ = "abcdefghi";

assert(substr($_, 0, 6) eq 'abcdef');
assert(substr($_, 1, 5) eq 'bcdef');
assert(substr($_, 2, 4) eq 'cdef');
assert(substr($_, 3, 3) eq 'def');
assert(substr($_, 4, 2) eq 'ef');
assert(substr($_, 5, 1) eq 'f');
assert(substr($_, 6, 0) eq '');

print "$0 - test passed!\n";
