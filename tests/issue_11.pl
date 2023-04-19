# issue 11 - regex 'g' flag isn't properly handled
use Carp::Assert;
$f = 'abcsftp> defsftp> ghi';
$f=~s/sftp> //g;
assert($f eq 'abcdefghi');

$f = 'dels abcdefghi';
$f=~s/^.*s //g;
assert($f eq 'abcdefghi');

$f = 'abcsftp> defSFTP> ghi';
$f=~s/sftp> //ig;
assert($f eq 'abcdefghi');

$f = 'delS abcdefghi';
$f=~s/^.*s //i;
assert($f eq 'abcdefghi');

$f = 'abcsftp> defsftp> ghi';
$f=~s/sftp> //;
assert($f eq 'abcdefsftp> ghi');

$f = 'dels abcdefghi';
$f=~s/^.*s //;
assert($f eq 'abcdefghi');

$f = 'abcsftp> defsftp> ghi';
$f=~s/sftp> /$&/;
assert($f eq 'abcsftp> defsftp> ghi');

$f = 'abcdefghis ';
$f=~s/^(.*)s /$1/;
assert($f eq 'abcdefghi');

$f = 'dels abcdefghi';
$f=~s/^(.*)s /$& $1/;
assert($f eq 'dels  delabcdefghi');

$ndx = 0;
@arr = ('aabbcc');
$arr[$ndx] =~ s/a/b/g;
assert($arr[0] eq 'bbbbcc');

$arr[0] = 'aabbcc';
$arr[$ndx] =~ s/a/b/;
assert($arr[0] eq 'babbcc');

$arr[0] = '$abbcc';
$arr[$ndx] =~ s/./b/;
assert($arr[0] eq 'babbcc');

$key = 'key';
%hash = (key=>'aabbcc');
$hash{$key} =~ s/a/b/g;
assert($hash{$key} eq 'bbbbcc');

$hash{key} = 'aabbcc';
$hash{$key} =~ s/a/b/;
assert($hash{key} eq 'babbcc');

$hash{key} = '$abbcc';
$hash{key} =~ s/./b/;
assert($hash{$key} eq 'babbcc');

print "$0 - test passed!\n";
