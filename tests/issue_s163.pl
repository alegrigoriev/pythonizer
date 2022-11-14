# issue_s163 - simple sort generating bad code
use Carp::Assert;

my %tmpRtrHash = (Rtr1=>'a', rtr2=>'b', RTR3=>'c');
my @sorted_router = sort {lc($a) cmp lc($b)} (keys %tmpRtrHash);

assert(@sorted_router == 3);
assert($sorted_router[0] eq 'Rtr1');
assert($sorted_router[1] eq 'rtr2');
assert($sorted_router[2] eq 'RTR3');

print "$0 - test passed!\n";
