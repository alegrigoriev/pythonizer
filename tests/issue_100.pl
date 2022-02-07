# issue 100 - Bad code generated if we have if/else on the same line

use Carp::Assert;

$shelf = '';
if($shelf eq '') {$var = "str1";}else {$var = "str2";}
assert($var eq 'str1');
$shelf = 'a';
if($shelf eq '') {$var = "str1";}else {$var = "str2";}
assert($var eq 'str2');

print "$0 - test passed!\n";
