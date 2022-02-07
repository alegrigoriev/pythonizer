# issue 112 - !~ generates the same code as =~

use Carp::Assert;

assert('abc' =~ /a/);
assert('abc' !~ /z/);

print "$0 - test passed!\n";
