# issue s281 - UNIVERSAL::isa(\*FH, 'GLOB') should return 1
use Carp::Assert;

open(FH, '<', $0);
assert(UNIVERSAL::isa(\*FH, 'GLOB'));

close(FH);
print "$0 - test passed!\n";
