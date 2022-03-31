# issue time - the time function when followed by + or - wasn't parsing properly
use Carp::Assert;
my $now1 = time-0;
my $now2 = time+0;
my $now3 = time;

$eps = 2;
assert(abs($now1-$now2) < $eps);
assert(abs($now2-$now3) < $eps);
assert(abs($now1-$now3) < $eps);

print "$0 - test passed!\n";
