# Test 'defined'

use feature 'state';
use Carp::Assert;
eval {
	use IO::Handle;
};
assert(!$@ || $@ =~ /No module named/);

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
assert(defined NH->autoflush);
my %hash = (key=>'value');
assert(defined $hash{key});
assert(!defined $hash{nokey});
assert(defined $hash{key} ? 1 : 0);

mysub();

use lib '.';
use Exporting qw(munge);
assert(defined munge);
assert(munge('a') eq 'am');
assert(!defined &Exporting::framice);
assert(!defined &Export::munge);
assert(defined &Exporting::frobnicate);
assert(&Exporting::frobnicate('b') eq 'fb');

print "$0 - test passed!\n";
