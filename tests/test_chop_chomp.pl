# Tests for chop and chomp

use Carp::Assert;

$file = "myfile.ext\n";
$abc = "abc";

chomp $file;
assert($file eq 'myfile.ext');
chomp $abc;
assert($abc eq 'abc');

chop $file;
assert($file eq 'myfile.ex');
chop $abc;
assert($abc eq 'ab');

@out = ("file1\n", "file2\n", "file3\n");

$mix = 1;		# Mixed type
$result = '';
$result2 = '';
for $mix (@out){
    chomp $mix;
    $result .= $mix;
    chop $mix;
    $result2 .= $mix;
}

assert($result eq 'file1file2file3');
assert($result2 eq 'filefilefile');

print "$0 - test passed!\n";

