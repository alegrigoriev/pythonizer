# issue 109: References to special variables in subscripts or hash keys during string interpolation generates incorrect code

use Carp::Assert;

$_ = 0;
my @arr = (1,2);
assert($arr[$_] == 1);
assert("Element is $arr[$_]" eq 'Element is 1');

my %hash = (k1=>'v1');
"k1" =~ /(.*)/;
assert($1 eq 'k1');
assert($hash{$1} eq 'v1');
assert("Hash value is $hash{$1}" eq 'Hash value is v1');

print "$0 - test passed!\n";
