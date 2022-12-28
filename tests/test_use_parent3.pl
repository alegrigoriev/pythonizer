# test 'use parent' without -norequire and without using the parent package
use lib '.';
package My::Class;
use parent 'My::BaseClass';
use Carp::Assert;
assert(My::Class->isa('My::BaseClass'));
assert(grep {$_ eq 'My::BaseClass'} @ISA);
print "$0 - test passed!\n";
