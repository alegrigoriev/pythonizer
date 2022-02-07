# issue 26 - open without a specified mode incorrectly defaults to 'w' (write)
use Carp::Assert;

my $passed = 0;
open(FH, "non-existing.file") or $passed = 1;
assert($passed);

$passed = 0;
if(open(FH, "not.there")) {
    assert(0);
} else {
    $passed = 1;
}
assert($passed);

print "$0 - test passed!\n";
