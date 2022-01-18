# Subtest of test_global_namespace
#
$pack::above = 1;
package pack;
use Carp::Assert;

$pack::packvar;
$packv;
my $filevar;
$pack::initialized = 88;
$pack::is = 'is';
@packv = (1, 2);

$pack::packvar += 42;
$packv += 12;
$filevar++;

sub check_pack
{
    assert($pack::above == 1);
    assert($pack::packvar == 42);
    assert($pack::packv == 12);
    assert($pack::packv[0] == 1);
    assert($pack::initialized == 88);
    assert($pack::is eq 'is');
    our $packv;
    assert($packv == 12);
    assert($filevar == 1);
    our $here_only;
    assert(++$here_only == 1);
    if(($here_only += 5) == 6) {
        ;
    } else {
        assert(0);
    }
}

check_pack() unless(caller);

print "$0 - test passed!\n" unless(caller);
1;
