# issue s282n - Implement $ ^ S - this test uses $EXCEPTIONS_BEING_CAUGHT in a separate module
use Carp::Assert;
use English;

sub evalsub {
    assert($EXCEPTIONS_BEING_CAUGHT);
}

1;
