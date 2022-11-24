# error test for eval cases not handled

use Carp::Assert;
$to_eval = '$result = 4';
$result = 2;

eval "$to_eval";        # pythonizer doesn't handle this

assert($result == 4);
print "Should complain about eval with interpolated string not handled\n";
print "$0 - test passed!\n";
