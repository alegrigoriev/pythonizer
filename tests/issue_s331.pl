# issue s331 - Change errors for use overload ++ / -- to warnings
#!/usr/bin/perl

use strict;
use warnings;
use lib '.';
use MyNumber;
use Carp::Assert;

# Test add (+)
my $a =
MyNumber->new(5);
my $b = MyNumber->new(3);
my $c = $a + $b;
assert($c->value == 8, 'Test add (+)');
# Test subtract (-)

my $d = $a - $b;
assert($d->value == 2, 'Test subtract (-)');
# Test increment (++)

my $e = MyNumber->new(4);
$e++;
assert($e->value == 5, 'Test increment (++)');
# Test decrement (--)

my $f = MyNumber->new(7);
$f--;
assert($f->value == 6, 'Test decrement (--)');
# Print a message to indicate successful testing

print "$0 - test passed!\n";
