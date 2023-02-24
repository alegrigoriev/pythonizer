# issue s291 - pushing to @ARGV doesn't work properly
use Carp::Assert;

push @ARGV, 1;
assert(scalar(@ARGV) == 1);
assert($ARGV[0] == 1);

unshift @ARGV, 2;

assert(scalar(@ARGV) == 2);
assert($ARGV[0] == 2);
assert($ARGV[1] == 1);

$ARGV[0] = 3;
assert($ARGV[0] == 3);

my $one = pop @ARGV;
assert($one == 1);
assert(scalar(@ARGV) == 1);

push @ARGV, "$0 - test passed!\n";
push @ARGV, 7;
my $three = shift @ARGV;
assert($three == 3);
assert(scalar(@ARGV) == 2);

print $ARGV[-2];
