# Test goto &sub statement
use Carp::Assert;

sub sub1
{
    goto &sub2;
    assert(0);
}

my $ctr = 0;

sub sub2
{
    $arg1 = shift;
    $arg2 = shift;

    $ctr = $arg1 + $arg2;
}

sub1(2, 3);
assert($ctr == 5);
print "$0 - test passed!\n";

