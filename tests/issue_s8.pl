# Args to regex need to be converted to str
use Carp::Assert;

123 =~ /(1.*)(2.*)(3.*)/;
assert($1 == 1 && $2 == 2 && $3 == 3);

$arg = 12;
$arg .= 3;
assert($arg == 123);

$arg = 123;
$arg =~ /(1.*)(2.*)(3.*)/;
assert($1 == 1 && $2 == 2 && $3 == 3);

$x = 123;
$x =~ s/1/2/;
assert($x == 223);

$x = 123;
$x =~ tr/1/2/;
assert($x == 223);

$x = 123;
$y = 234;
$x =~ s/$x/$y/;
assert($x == 234);
assert($y == 234);

$x = 123;
$y = 234;
$x =~ s'$x'$y';
assert($x == 123);
assert($y == 234);

$_ = 113;
s/1/2/;
assert($_ == 213);

$_ = 113;
assert(s/9/2/ == 0);
assert(s/1/2/ == 1);
assert($_ == 213);

$_ = 113;
s/1/2/g;
assert($_ == 223);

$_ = 113;
assert(s/1/2/g == 2);
assert($_ == 223);

$_ = 123;
tr/1/2/;
assert($_ == 223);

$_ = 123;
tr/13/29/;
assert($_ == 229);

$_ = 123;
assert(tr/13/29/ == 2);
assert($_ == 229);

$x = 123;
$y = $x =~ s/1/2/;
assert($x == 223);
assert($y == 1);

$x = 123;
$y = ($x =~ s/1/2/);
assert($x == 223);
assert($y == 1);

$x = 123;
assert($x =~ s/1/2/ == 1);
assert($x == 223);

$x = 123;
$y = $x =~ s/1/2/g;
assert($x == 223);
assert($y == 1);

$x = 123;
$y = $x =~ tr/1/2/;
assert($x == 223);
assert($y == 1);

$x = 123;
$y = ($x =~ tr/1/2/);
assert($x == 223);
assert($y == 1);

$x = 123;
assert($x =~ tr/1/2/ == 1);
assert($x == 223);

$x = 113;
$y = $x =~ s/1/2/g;
assert($x == 223);
assert($y == 2);

$x = 113;
$y = $x =~ s/1/2/gr;
assert($x == 113);
assert($y == 223);

$x = 113;
$y = $x =~ tr/1/2/r;
assert($x == 113);
assert($y == 223);

$x = 123;
# _assign_global('main_', 'z', main_.x), _assign_global('main_', 'z', re.sub(r'c',r'a',main_.z,count=1))
# -or- _assign_global('main_', 'z', re.sub(r'c',r'a',_assign_global('main_', 'z', main_.x),count=1))
($z = $x) =~ s/3/1/;
assert($x == 123);
assert($z == 121);

$x = 133;
# _assign_global('main_', 'z', main_.x), _assign_global('main_', 'z', re.sub(re.compile(r'c'),r'a',main_.z,count=0))
($z = $x) =~ s/3/1/g;
assert($x == 133);
assert($z == 111);

$x = 123;
#_assign_global('main_', 'z', main_.x), _assign_global('main_', 'z', main_.z.translate(str.maketrans(r'c',r'a')))
($z = $x) =~ tr/3/1/;
assert($x == 123);
assert($z == 121);

my ($my_a, $my_b, $my_c);
$my_a = 123;
($my_c = $my_a) =~ s/3/1/;
assert($my_a == 123);
assert($my_c == 121);

$my_a = 133;
($my_c = $my_a) =~ s/3/1/g;
assert($my_a == 133);
assert($my_c == 111);

$my_a = 123;
($my_c = $my_a) =~ tr/3/1/;
assert($my_a == 123);
assert($my_c == 121);

$my_b = $my_a =~ s/[12]/9/g;
assert($my_a == 993);
assert($my_b == 2);

my @arr = (123, 456);

$arr[0] =~ s/$arr[1]/$arr[0]/;
assert($arr[0] == 123);
assert($arr[1] == 456);

$arr[0] =~ s/$arr[0]/$arr[1]/;
assert($arr[0] == 456);
assert($arr[1] == 456);

$arr[0] =~ tr/4/9/;
assert($arr[0] == 956);

$i = 0;
$arr[$i++] =~ s/9/4/;
assert($arr[0] == 456);
assert($i == 1);

$arr[$i++] =~ tr/4/9/;
assert($arr[1] == 956);
assert($i == 2);

# tr examples from the 'net:

my $str = 123;
$str =~ tr/13/24/;
assert($str == 224);

$_ = 123456789;
$k=tr/0-9/9/;
assert($_ == 999999999);
assert($k == 9);

tr/999/123/;	# 2 and 3 are ignored
assert($_ == 111111111);

$ldel = 123;
$ldel =~ tr/\N{U+0}-\N{U+31}//d;
assert($ldel == 23);

print "$0 - test passed!\n";
