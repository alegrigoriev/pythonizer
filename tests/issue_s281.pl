# issue s281 - UNIVERSAL::isa(\*FH, 'GLOB') should return 1
use Carp::Assert;

open(FH, '<', $0);
assert(UNIVERSAL::isa(\*FH, 'GLOB'));
close(FH);

*SUB = sub { 0 };
assert(UNIVERSAL::isa(\*SUB, 'GLOB'));

my $sub = sub { 1 };
assert(UNIVERSAL::isa($sub, 'CODE'));

print "$0 - test passed!\n";
