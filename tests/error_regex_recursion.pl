# error test for not supported regex recursion
use Carp::Assert;

assert('staats' =~ /(\w)(?:(?R)|\w?)\1/);
print "$0 - test passed!\n";
