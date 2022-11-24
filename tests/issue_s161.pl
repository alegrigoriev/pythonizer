# issue s161 - misplaced ~ operator doesn't translate properly
use Carp::Assert;

$line = "pat5 here";
$BLANK = 'XXXX';

$line = ~s/pat5 .*/pat5 $BLANK/;

assert($line ne 'pat5 XXXX');
assert($line != 0);

print "$0 - test passed\n";
