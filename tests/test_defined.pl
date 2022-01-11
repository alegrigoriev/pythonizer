# Test 'defined'

use feature 'state';
use Carp::Assert;
use IO::Handle;

$j=0;
my $k = 0;

sub mysub {
    state $s = 0;
    local $l = 0;
    my $m = 0;

    assert(defined $s);
    assert(defined $l);
    assert(defined $m);
    assert(!defined $i);
    assert(defined $j);
    assert(defined $k);
    assert(defined &mysub);
    assert(defined $::j);
}

assert(!defined $i);
assert(defined $j);
assert(defined $::j);
assert(defined $k);
assert(defined &mysub);
#assert(defined IO::Handle);
assert(defined STDERR);
assert(defined lc);
open(NH, '>/dev/null');
assert(defined NH);

mysub();

print "$0 - test passed!\n";
