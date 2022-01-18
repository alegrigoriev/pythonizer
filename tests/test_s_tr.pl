# Test the substitution
use Carp::Assert;

$x = 'abc';
$x =~ s/a/b/;
assert($x eq 'bbc');

$x = 'abc';
$x =~ tr/a/b/;
assert($x eq 'bbc');

$x = 'abc';
$y = 'bcd';
$x =~ s/$x/$y/;
assert($x eq 'bcd');
assert($y eq 'bcd');

$x = 'abc';
$y = 'bcd';
$x =~ s'$x'$y';
assert($x eq 'abc');
assert($y eq 'bcd');

$_ = 'aac';
s/a/b/;
assert($_ eq 'bac');

$_ = 'aac';
assert(s/z/b/ == 0);
assert(s/a/b/ == 1);
assert($_ eq 'bac');

$_ = 'aac';
s/a/b/g;
assert($_ eq 'bbc');

$_ = 'aac';
assert(s/a/b/g == 2);
assert($_ eq 'bbc');

$_ = 'abc';
tr/a/b/;
assert($_ eq 'bbc');

$_ = 'abc';
tr/ac/bz/;
assert($_ eq 'bbz');

$_ = 'abc';
assert(tr/ac/bz/ == 2);
assert($_ eq 'bbz');

$x = 'abc';
$y = $x =~ s/a/b/;
assert($x eq 'bbc');
assert($y == 1);

$x = 'abc';
$y = $x =~ s/a/b/g;
assert($x eq 'bbc');
assert($y == 1);

$x = 'abc';
$y = $x =~ tr/a/b/;
assert($x eq 'bbc');
assert($y == 1);

$x = 'aac';
$y = $x =~ s/a/b/g;
assert($x eq 'bbc');
assert($y == 2);

$x = 'aac';
$y = $x =~ s/a/b/gr;
assert($x eq 'aac');
assert($y eq 'bbc');

$x = 'aac';
$y = $x =~ tr/a/b/r;
assert($x eq 'aac');
assert($y eq 'bbc');

$x = 'abc';
# _assign_global('main_', 'z', main_.x), _assign_global('main_', 'z', re.sub(r'c',r'a',main_.z,count=1))
# -or- _assign_global('main_', 'z', re.sub(r'c',r'a',_assign_global('main_', 'z', main_.x),count=1))
($z = $x) =~ s/c/a/;
assert($x eq 'abc');
assert($z eq 'aba');

$x = 'acc';
# _assign_global('main_', 'z', main_.x), _assign_global('main_', 'z', re.sub(re.compile(r'c'),r'a',main_.z,count=0))
($z = $x) =~ s/c/a/g;
assert($x eq 'acc');
assert($z eq 'aaa');

$x = 'abc';
#_assign_global('main_', 'z', main_.x), _assign_global('main_', 'z', main_.z.translate(str.maketrans(r'c',r'a')))
($z = $x) =~ tr/c/a/;
assert($x eq 'abc');
assert($z eq 'aba');

my ($my_a, $my_b, $my_c);
$my_a = 'abc';
($my_c = $my_a) =~ s/c/a/;
assert($my_a eq 'abc');
assert($my_c eq 'aba');

$my_a = 'acc';
($my_c = $my_a) =~ s/c/a/g;
assert($my_a eq 'acc');
assert($my_c eq 'aaa');

$my_a = 'abc';
($my_c = $my_a) =~ tr/c/a/;
assert($my_a eq 'abc');
assert($my_c eq 'aba');

$my_b = $my_a =~ s/[ab]/z/g;
assert($my_a eq 'zzc');
assert($my_b == 2);

my @arr = ('abc', 'def');

$arr[0] =~ s/$arr[1]/$arr[0]/;
assert($arr[0] eq 'abc');
assert($arr[1] eq 'def');

$arr[0] =~ s/$arr[0]/$arr[1]/;
assert($arr[0] eq 'def');
assert($arr[1] eq 'def');

$arr[0] =~ tr/d/x/;
assert($arr[0] eq 'xef');

$i = 0;
$arr[$i++] =~ s/x/d/;
assert($arr[0] eq 'def');
assert($i == 1);

$arr[$i++] =~ tr/d/z/;
assert($arr[1] eq 'zef');
assert($i == 2);


# A case that was failing from compass.pl:
sub maketbl
{
	my $file = shift;
        my $full = $file =~ s/.full//;
	assert($file eq 'f');
	assert($full == 1);
}
maketbl('f.full');

print "$0 - test passed!\n";
