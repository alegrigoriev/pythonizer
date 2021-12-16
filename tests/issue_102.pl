# issue 102 - Array assignment from builtin list-returning function generates bad code
use Carp::Assert;

sub sub1 { 'sub1' }
sub sub2 { shift }

my %hash = (k1=>'v1');
my @a = ('b', 'c', 'a');

my @arr = (sub1(), sub2('sub2'), $hash{k1});
assert(join('', @arr) eq 'sub1sub2v1');
my @ar1 = reverse @a;
assert(join('', @ar1) eq 'acb');
my @ar2 = (reverse @a);
assert(join('', @ar2) eq 'acb');
my @ar3 = (reverse sort @a);
assert(join('', @ar3) eq 'cba');
my @ar4 = (sort @a);
assert(join('', @ar4) eq 'abc');
my @ar5 = ('a', @ar4, %hash, 'b');
assert(join('', @ar5) eq 'aabck1v1b');

print "$0 - test passed!\n";
