# issue s135 - grep expression with substitute and/or angle brackets glob does not work
use Carp::Assert;

# First some canned cases

@arr1 = ('abc', 'def', 'GHI', '012');
@arr2 = grep { s/[A-Z][A-Z][A-Z]/aaa/i } @arr1;
assert(@arr2 == 3);
assert($arr2[0] eq 'aaa' && $arr2[1] eq 'aaa' && $arr2[2] eq 'aaa');

@arr1 = ('abc', 'def', 'GHI', '012');       # Reset it because the first grep clobbers the array (in perl)
@arr3 = grep { tr/a/x/ } @arr1;
assert(@arr3 == 1);
assert($arr3[0] eq 'xbc');

# From the netdb source code:

$ERRSDIR = '.';

@dat = reverse grep { s(.*[/\\])() }
<$ERRSDIR/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]>;

assert(@dat == 2);
assert($dat[0] eq '11111135');
assert($dat[1] eq '00000135');

@dtr = reverse grep { tr/35/89/ }
<$ERRSDIR/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]>;

assert(@dtr == 2);
assert($dtr[0] =~ /11111189$/);
assert($dtr[1] =~ /00000189$/);

print "$0 - test passed!\n";

