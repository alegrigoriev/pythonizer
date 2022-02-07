# issue 33 - keys is a method, not a property

use Carp::Assert;

my %hash = (k1=>'v1', k2=>'v2');
my @arr = keys %hash;

assert(@arr == 2);
assert(($arr[0] eq 'k1' && $arr[1] eq 'k2') ||
       ($arr[1] eq 'k1' && $arr[0] eq 'k2'));

print "$0 - test passed!\n";
