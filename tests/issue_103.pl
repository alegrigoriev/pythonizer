# Issue 103: Hash iterator idiom generates bad code
use Carp::Assert;

$ENV{TEST_KEY} = "test_value";

$foundit = 0;
while(($key, $val) = each %ENV) {
    if($key eq 'TEST_KEY' && $val eq 'test_value') {
        $foundit = 1;
        last;
    }
}

assert($foundit);

print "$0 - test passed!\n";
