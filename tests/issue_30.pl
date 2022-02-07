# issue 30 - Perl variables/arrays/hashes are created out of whole cloth - attempt to handle some of these

use v5.25;
no strict;
use Carp::Assert;

$options{this} = 1;

# Hash in scalar context: As of Perl 5.25 the return was changed to be the count of keys in the hash.
assert(%options == 1);
assert(1 == %options);
assert(scalar(%options) == 1);
$c = %options;
assert($c == 1);
my $cc = %options;
assert($cc == 1);
$d = (1, 2, 3, %options);       # Comma operator, not a list
assert($d == 1);
$complex{k1}{k2}[0] = %options;
assert($complex{k1}{k2}[0] == 1);
#$e = () = %options;     # List context: changes the hash to a list of 2 elements and returns 2
#assert($e == 2);

assert($options{this} == 1);

$arr[$i++] = 4;
assert($i == 1);
assert(@arr == 1);
assert($arr[0] == 4);


print "$0 - test passed!\n";
