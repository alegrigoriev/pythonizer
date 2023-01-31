# issue s254a - Empty list in scalar context should be changed to undef
# This version is split into 2 files to see how import works
# Written (mostly) by chatGPT
# pragma pythonizer -M
use Carp::Assert;
use lib '.';
require issue_s254m;

# Check if the empty subroutine returns undef
assert(not defined(empty()));

# Check if the empty subroutine returns an empty list
assert(not scalar(empty()));

# Check if the empty subroutine returns the correct value when called in list context
my @result = empty();
assert(scalar(@result) == 0);

# Check if the empty subroutine returns the correct value when called in scalar context
my $result = scalar empty();
assert(not defined($result));

# Check if the empty subroutine returns the correct value when called in scalar context w/o scalar function
$result = empty();
assert(not defined($result));

print "$0 - test passed!\n";
