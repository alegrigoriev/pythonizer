# issue s30 - "return" inside of a loop in a BEGIN block generates incorrect code
# This test has the return in an expression
use Carp::Assert;

BEGIN {
    for(my $i = 0; $i < 10; $i++) {
        $j = 2 and return if($i == 2);
    }
    assert(0);  # test failed
}
print "$0 - test passed!\n";
