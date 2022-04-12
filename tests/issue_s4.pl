# use Config with -m doesn't work
use Carp::Assert;
# pragma pythonizer -m

use Config;
assert(length($Config{path_sep}) == 1);

print "$0 - test passed!\n";
