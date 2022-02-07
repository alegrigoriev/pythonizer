# issue 15 - Missing variable in generated python from compound conditional
use Carp::Assert;

$ST_GLOBAL = 1;
$prev_state = 0;
$state_chg = 1;
$bool = $state_chg && ($prev_state == $ST_GLOBAL);
assert(!$bool);

$prev_state = 1;
$bool = $state_chg && ($prev_state == $ST_GLOBAL);
assert($bool);

$state_chg = 0;
$bool = $state_chg && ($prev_state == $ST_GLOBAL);
assert(!$bool);
print "$0 - test passed!\n";
