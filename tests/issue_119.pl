# issue 119 - Last element index ( $# ) of a hash causes internal error
use Carp::Assert;

$package = {type=>[0,1,2]};

assert(scalar(@{$package->{type}}) == 3);
assert($#{$package->{type}} == 2);

print "$0 - test passed!\n";
