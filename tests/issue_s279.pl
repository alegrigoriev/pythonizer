# issue s279 - grep thru multiple arrays generates bad code
use Carp::Assert;
no warnings 'experimental';

my @EXPORT = qw(b c);
my @A = qw(a);

grep($routines{$_}++,@A,@EXPORT);

assert($routines{a} == 1);
assert($routines{b} == 1);
assert($routines{c} == 1);

my @turntable1 = ('AA', 'BB');
my @turntable2 = ('CC', 'DD');
my $microphone = 'EE';
my @all = map(lc, @turntable1, @turntable2, $microphone);
assert(@all ~~ ['aa', 'bb', 'cc', 'dd', 'ee']);

print "$0 - test passed!\n";
