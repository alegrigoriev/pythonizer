# issue s356 - Conditionally assigned arrayref is being incorrectly initialized to an empty array instead of undef
no warnings 'experimental';
use Carp::Assert;

sub testit {
    my $arg = shift;
    my $date;

    $date = [2023, 2, 22] if $arg;
    return $date;
}

assert(!defined testit(0));
assert(testit(1) ~~ [2023, 2, 22]);

# Try a real array that initialized in a conditional:

sub test2 {
    my $arg = shift;
    my @zone;
    if(0) {
        my @tmp = @{ testit(1) };
    }
    if(1) {
        my @tmp;

        push(@tmp, 1) if $arg;

        @zone = @tmp;
    }

    return @zone;
}

my @z1 = test2(0);
assert(scalar @z1 == 0);

my @z2 = test2(1);
assert(scalar @z2 == 1);
assert($z2[0] == 1);

print "$0 - test passed!\n";
