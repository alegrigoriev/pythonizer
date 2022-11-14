# issue s152 - missing ';' on require should execute next line
use Carp::Assert;
require v5.24
&CallSub();

sub CallSub {
    $called = 1;
}

assert($called);

print "$0 - test passed\n";
