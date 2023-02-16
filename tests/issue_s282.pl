# issue s282 - Implement $^S
use Carp::Assert;

assert(!$^S);

sub evalsub {
    assert($^S);
}

eval {
    evalsub();
};
assert(!$@, 'Test in eval failed!');

use English;

assert(!$EXCEPTIONS_BEING_CAUGHT);

eval {
    assert($EXCEPTIONS_BEING_CAUGHT);
};
assert(!$@, 'Test w/English in eval failed!');

print "$0 - test passed!\n";
