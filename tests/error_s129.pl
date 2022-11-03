# error test for issue s129: switch/given
#
# We don't currently support next/continue in a case/when unless it is
# the last statement and it's not conditional.
use v5.34;
use Carp::Assert;
no warnings qw/experimental/;

my $var = 3;
my ($three, $digit);
given($var) {
    when (3) {
        $three++;
        if($var == 3) {
            continue;       # Not currently supported for pythonizer
        } else {
            assert(0);
        }
    }
    when (/\d/) {
        $digit++
    }
}
assert($three == 1 && $digit == 1);

print "$0 - test passed!\n"
