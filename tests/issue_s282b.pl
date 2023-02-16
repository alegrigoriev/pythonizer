# issue s282b - Implement $^S - this test only uses it in a separate module and that module uses English
use Carp::Assert;
use lib '.';
require issue_s282n;

eval {
    evalsub();
};
assert(!$@, 'Test in eval failed!');

print "$0 - test passed!\n";
