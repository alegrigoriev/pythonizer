# error test for issue s129: switch/given
#
# We don't currently support next/continue in a case/when unless it is
# the last statement and it's not conditional.
use Carp::Assert;
use Switch;

my $var = 3;
my ($three, $digit);
switch($var) {
    case (3) {
        $three++;
        if($var == 3) {
            next;       # Not currently supported for pythonizer
        } else {
            assert(0);
        }
    }
    case (/\d/) {
        $digit++
    }
}
assert($three == 1 && $digit == 1);

print "$0 - test passed!\n"
