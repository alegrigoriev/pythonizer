# issue chop
use Carp::Assert;

$_ = 'a';
chop;
assert($_ eq '');
$i = "abc";
chop $i;
assert($i eq 'ab');
$j = 'a';
chop ($i, $j);
assert($i eq 'a' && $j eq '');
@arr = ('abc', 'def', 'ghi');
chop @arr;
assert($arr[0] eq 'ab' && $arr[1] eq 'de' && $arr[2] eq 'gh');
%hash = (k1=>'v1', k2=>'w2');
chop %hash;
assert($hash{k1} eq 'v' && $hash{k2} eq 'w');
print "$0 - test passed!\n";
