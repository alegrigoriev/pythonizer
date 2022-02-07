# issue 28: Incorrect code for shift/pop of an empty array
use Carp::Assert;

sub mySub {
    $thresh = shift;
    $thresh = 1000
        unless defined $thresh;
    $thresh;
}

assert(mySub() == 1000);
assert(mySub(10) == 10);

print "$0 - test passed!\n";
