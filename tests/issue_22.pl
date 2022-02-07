# issue 22 - Octal numbers need to get 0o in python output

use Carp::Assert;

assert(0123 == 0x53);
assert("\123" eq chr 0x53);

print "$0 - test passed!\n";
