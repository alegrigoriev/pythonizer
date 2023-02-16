# issue s273 - Multi-assignment to an arrayref and a list of scalars generates bad code
use Carp::Assert;
no warnings;

sub test_it
{
    my $arrayref = shift;

    @$arrayref = ($scalar1, $scalar2) = @_;
}

my $arrayref = [1,2];
test_it($arrayref, 3, 4, 5);

assert($arrayref ~~ [3,4]);
assert($scalar1 == 3);
assert($scalar2 == 4);

print "$0 - test passed!\n";
