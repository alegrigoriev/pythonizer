# issue s282m - Implement $^S - this test uses $^S in a separate module
use Carp::Assert;

sub evalsub {
    assert($^S);
}

1;
