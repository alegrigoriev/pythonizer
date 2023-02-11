# issue s70u - encoding issues - try unicode in identifiers
# -*- coding: utf-8 -*-
use utf8;
use Carp::Assert;

my $Π = 3.14159;
assert ($Π > 3.14 && $Π < 3.15);

assert("The value of π is $Π" == 'The value of Π is 3.14159');

my $Σ = 1 + 2;
assert($Σ == 3);

my $烝𝟜 = 14;
assert($烝𝟜 == 14);

print "$0 - test passed!\n";

