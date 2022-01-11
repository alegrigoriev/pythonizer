# Test use constant using examples in the documentation
use Carp::Assert;

my $PI = 3;

use constant PI    => 4 * atan2(1, 1);

my @PI = (3, 1);

assert((PI-3.14159) < 1E-3);
assert($PI == 3);
assert($PI[0] == 3 && $PI[1] == 1);
use constant DEBUG => 0;
assert(DEBUG == 0);

#print "Pi equals ", PI, "...\n" if DEBUG;
#

$SEC = 42;

use constant {
    SEC   => 0,
    MIN   => 1,
    HOUR  => 2,
    MDAY  => 3,
    MON   => 4,
    YEAR  => 5,
    WDAY  => 6,
    YDAY  => 7,
    ISDST => 8,
};

assert(SEC== 0 && ISDST==8);
assert($SEC == 42);

use constant WEEKDAYS => qw(
    Sunday Monday Tuesday Wednesday Thursday Friday Saturday
);

assert((WEEKDAYS)[0] eq 'Sunday');
assert((WEEKDAYS)[1] eq 'Monday');
assert((WEEKDAYS)[2] eq 'Tuesday');
assert((WEEKDAYS)[6] eq 'Saturday');

print "$0 - test passed!\n";
