# issue s360 - Subpackage with the same name as any parent package causes the module to overwrite the parent namespace

use strict;
use warnings;
use Carp::Assert;
use lib '.';
use A::B;

my $a_b = A::B->new;
my $result = $a_b->hello;
assert($result eq "Hello from A::B::A!", "A::B::A hello() method failed.");

$result = $a_b->hello_b;
assert($result eq "Hello from A::B::B!", "A::B::B hello() method failed.");

use A;
my $a = A->new;
$result = $a->hello;
assert($result eq "Hello from A::A!", "A::A hello() method failed.");

print "$0 - test passed.\n";

