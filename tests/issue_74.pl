# issue 74 - ++ and -- generate bad code in expressions
use Carp::Assert;

$t = 0;
assert($t++ == 0);
assert($t == 1);
assert(++$t == 2);
assert($t == 2);
assert($t-- == 2);
assert($t == 1);
assert(--$t == 0);
assert($t == 0);
$t++;
assert($t == 1);
++$t;
assert($t == 2);
$t--;
assert($t == 1);
--$t;
assert($t == 0);

@arr = (0);
assert($arr[$t]++ == 0);
assert($arr[$t] == 1);
assert(++$arr[$t] == 2);
assert($arr[$t] == 2);
assert($arr[$t]-- == 2);
assert($arr[$t] == 1);
assert(--$arr[$t] == 0);
assert($arr[$t] == 0);
$arr[$t]++;
assert($arr[$t] == 1);
++$arr[$t];
assert($arr[$t] == 2);
$arr[$t]--;
assert($arr[$t] == 1);
--$arr[$t];
assert($arr[$t] == 0);
assert($#arr++ == 0);
assert($#arr == 1);
assert(!defined $arr[1]);
assert(--$#arr == 0);
assert($#arr == 0);

%has = (0=>0);
assert($has{$t}++ == 0);
assert($has{$t} == 1);
assert(++$has{$t} == 2);
assert($has{$t} == 2);
assert($has{$t}-- == 2);
assert($has{$t} == 1);
#LOL don't even think about it!  assert(--$has[$t++] == 0);
#assert($t == 1);
#assert(--$t == 0);
$i = 0;
assert(--$has{$t} == $i++);
assert($i == 1);
assert($has{$t} == 0);
$has{$t}++;
assert($has{$t} == 1);
++$has{$t};
assert($has{$t} == 2);
$has{$t}--;
assert($has{$t} == 1);
--$has{$t};
assert($has{$t} == 0);

print "$0 - test passed!\n";
