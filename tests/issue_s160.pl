# issue s160 - Assignment to @hash{@keys} generates bad code
use Carp::Assert;

my @typearray = ('a', 'b', 'b', 'c');
# Eliminate duplicate types and models
undef %unique;
@unique{@typearray}={};
@typearray = keys %unique;
@typearray = sort @typearray;

assert(@typearray == 3);
assert($typearray[0] eq 'a');
assert($typearray[1] eq 'b');
assert($typearray[2] eq 'c');

print "$0 - test passed!\n";

