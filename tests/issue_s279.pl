# issue s279 - grep thru multiple arrays generated bad code
use Carp::Assert;

my @EXPORT = qw(b c);
my @A = qw(a);

grep($routines{$_}++,@A,@EXPORT);

assert($routines{a} == 1);
assert($routines{b} == 1);
assert($routines{c} == 1);

print "$0 - test passed!\n";
