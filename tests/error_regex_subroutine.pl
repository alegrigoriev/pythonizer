# error test - regex subroutines are not supported
use Carp::Assert;

assert('acbac' =~ /(?+1)(?'name'[abc])(?1)(?-1)(?&name)/);
print "$0 - test passed!\n";
