# issue s255 - join with ? : to determine the join char generates bad code
use Carp::Assert;

$USE_PARAM_SEMICOLONS = 0;

sub mySub {
    my @pairs = ('a', 'b');
    return join($USE_PARAM_SEMICOLONS ? ';' : '&',@pairs);
}

assert(mySub() eq 'a&b');
$USE_PARAM_SEMICOLONS = 1;
assert(mySub() eq 'a;b');

print "$0 - test passed!\n";
