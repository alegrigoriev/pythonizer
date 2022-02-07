# issue 14: Changing the length of an array by setting $#Arr doesn't work

use Carp::Assert;

$#words++;
assert(@words == 1);
++$#words;
assert(@words == 2);
$words[++$#words] = 'new Last';
assert(@words == 3);
assert($words[-1] eq 'new Last');
$#words = 0;
assert(@words == 1);
$#words = -1;
assert(@words == 0);

print("$0 - test passed!\n");
