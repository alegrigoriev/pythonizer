# Subtest of test_global_namespace
#
$pack::above = 1;
package pack;
use Carp::Assert;

$pack::packvar = 42;
$packv = 12;

sub check_pack
{
    assert($pack::above == 1);
    assert($pack::packvar == 42);
    assert($pack::packv == 12);
    our $packv;
    assert($packv == 12);
}

check_pack();

print "$0 - test passed!\n" unless(caller);
1;
