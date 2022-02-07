# issue 61 - return is not a function in python

use Carp::Assert;

sub mySub {
    return;
}

$i = mySub();

assert(!defined $i);

print "$0 - test passed!\n";
