# issue s282n - Implement $ ^ S - this test uses $EXCEPTIONS_BEING_CAUGHT in a separate module
use Carp::Assert;
use English;

my $e = $EVAL_ERROR;        # testing specialvarsused
my $a = @_;
my $z = $0;
my $w = $^W;
my $n = $EXECUTABLE_NAMES;     # NOT a special var
sub evalsub {
    assert($EXCEPTIONS_BEING_CAUGHT);
}

1;
