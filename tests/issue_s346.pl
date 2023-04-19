# issue s346 - Array to Hash map idiom generates bad code
use strict;
use warnings;
use Carp::Assert;

# Given line
my %mn_form  = map { $_,1 } qw( M s o );

# Test using Carp::Assert
assert(scalar(keys %mn_form) == 3, 'mn_form hash should have 3 keys');
assert(exists $mn_form{'M'}, 'Key "M" should exist in mn_form');
assert(exists $mn_form{'s'}, 'Key "s" should exist in mn_form');
assert(exists $mn_form{'o'}, 'Key "o" should exist in mn_form');
assert($mn_form{'M'} == 1, 'Value of key "M" should be 1');
assert($mn_form{'s'} == 1, 'Value of key "s" should be 1');
assert($mn_form{'o'} == 1, 'Value of key "o" should be 1');

print "$0 - test passed!\n";
