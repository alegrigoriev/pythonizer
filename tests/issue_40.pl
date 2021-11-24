# issue_40: incorrect code for join operation
use Carp::Assert;
@ar=('a','b','c');
$j = join(',', @ar);
assert($j eq "a,b,c");
assert(join($ar[0],@ar) eq "aabac");
$thing1='xx';
$thing2='yy';
$thing3='zz';
assert(join('.', $thing1, $thing2, $thing3) eq "xx.yy.zz");
$bl = join(',');
assert($bl eq '');
print "$0 - passed!\n";
