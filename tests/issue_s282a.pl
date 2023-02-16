# issue s282a - Implement $^S - this test only uses it in a separate module
use Carp::Assert;
use lib '.';
require issue_s282m;

eval {
    evalsub();
};
assert(!$@, 'Test in eval failed!');

print "$0 - test passed!\n";
