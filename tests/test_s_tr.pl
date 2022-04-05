# Test the substitution and translation
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
$y = ($x =~ s/a/b/);
assert($x eq 'bbc');
assert($y == 1);

$x = 'abc';
assert($x =~ s/a/b/ == 1);
assert($x eq 'bbc');

$x = 'abc';
$y = $x =~ s/a/b/g;
assert($x eq 'bbc');
assert($y == 1);

$x = 'abc';
$y = $x =~ tr/a/b/;
assert($x eq 'bbc');
assert($y == 1);

$x = 'abc';
$y = ($x =~ tr/a/b/);
assert($x eq 'bbc');
assert($y == 1);

$x = 'abc';
assert($x =~ tr/a/b/ == 1);
assert($x eq 'bbc');

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

# tr examples from the 'net:

my $str = "abc";
$str =~ tr/ac/bd/;
assert($str eq 'bbd');

$str = "I'm fine. Thank you.";
my $count = ($str =~ tr/././);
assert($count == 2);

$count = ($str =~ tr/'./'./);
assert($count == 3);

$count = ($str =~ tr/'."//);
assert($count == 3);

$string = 'the cat sat on the mat.';
$string =~ tr/a-z/b/d;
assert($string eq ' b b   b.');

$var = 'IO::File';
$var =~ tr/::/./s;
assert($var eq 'IO.File');

$_ = 'a is for apple';
tr/a/z/;
assert($_ eq 'z is for zpple');

$_ = '123456789';
$k=tr/0-9/9/;
assert($_ eq '999999999');
assert($k == 9);

tr/999/123/;	# 2 and 3 are ignored
assert($_ eq '111111111');

$test='test ';
$test=~tr/ / /d;
assert($test eq 'test ');
$test=~tr/ //d;
assert($test eq 'test');

$_ = '131.1.1.1';
assert(tr/.// == 3);	# Counts but does not modify
assert($_ eq '131.1.1.1');

$ip = '192.168.1.2';
$k=($ip=~tr/0-9//);
assert($k == 8);
assert($ip eq '192.168.1.2');

$_ = 'bookkeeper';
tr/a-zA-Z//s;
assert($_ eq 'bokeper');


# complement tests here:

$_ = '131.1.1.1';
$k=tr/0-9//c;	# count all the non-digits
assert($k == 3);

@arr = ('131.1.1.1');
$k1= $arr[0] =~ tr/0-9//c;	# count all the non-digits
assert($k1 == 3);

$k2= (join('', @arr)) =~ tr/0-9//c;	# count all the non-digits
assert($k2 == 3);

$_ = 'cat321dog';
tr/a-zA-Z/ /cs;		# change non-alphas to single space
assert($_ eq 'cat dog');

$text='We search for word abba in this string';
$text=~tr/abba/?/cs;
assert($text eq '?a?abba?');

$text='We search for word abba in this string';
$cnt = $text=~tr/abba/?/cs;
assert($text eq '?a?abba?');
assert($cnt == 33);

$text='We search for word abba in this string';
$cnt = $text=~tr/abba//cd;
assert($text eq 'aabba');
assert($cnt == 33);

$_='We search for word abba in this string';
$cnt = tr/abba//cd;
assert($_ eq 'aabba');
assert($cnt == 33);

# A case that was failing from compass.pl:
sub maketbl
{
	my $file = shift;
        my $full = $file =~ s/.full//;
	assert($file eq 'f');
	assert($full == 1);
}
maketbl('f.full');

# A case from bootstrapping Perlscan.pm:

my $line = "[v1,v2,v3] = perllib.list_of_n(perllib.Array(), 3)";

# Change "[v1,v2,v3] = perllib.list_of_n(perllib.Array(), N)" -to-
#        v1 = v2 = v3 = None
if($line =~ /\[([\w.]+(?:,[\w.]+)*)\] = perllib\.list_of_n\(perllib.Array\(\), \d+\)/) {
    $line = ($1 =~ s/,/ = /gr) . " = None";
}

assert($line eq 'v1 = v2 = v3 = None');

# Another bootstrapping issue:
@ValClass=("((s))");
$balance=(join('',@ValClass)=~tr/()//);
assert($balance == 4);

# A case from Balanced.pm:
#
$ldel = "([{<junk\t>}])";
$ldel =~ tr/[](){}<>\0-\377/[[(({{<</ds;
#print "$ldel\n";
assert($ldel eq '([{<{[(');

$ldel = "\c@\ca\cz\o{1}abc";
$ldel =~ tr/\c@-\cz//d;
assert($ldel eq 'abc');

$ldel = "\c@\ca\cz\o{1}abc";
$ldel =~ tr/\o{0}-\cz//d;
assert($ldel eq 'abc');

$ldel = "\c@\ca\cz\o{1}abc\x{ 1A }";
$ldel =~ tr/\x{0}-\x1a//d;
assert($ldel eq 'abc');

$ldel = "\c@\ca\cz\o{1}'abc\x{ 1A }";
$ldel =~ tr/'\x{0}-\x1a//d;
assert($ldel eq 'abc');

$ldel = "\c@\ca\cz\o{1}abc\"\x{ 1A }";
$ldel =~ tr/\x{0}-\x1a"//d;
assert($ldel eq 'abc');

$ldel = "\c@\ca\cz\o{1}'abc\"\x{ 1A }";
$ldel =~ tr/'\x{0}-\x1a"//d;
assert($ldel eq 'abc');

$ldel = "\c@\ca\cz\o{1}-abc\x{ 1A }";
$ldel =~ tr'a-c''d;

assert($ldel eq "\c@\ca\cz\o{1}b\x1a");

$ldel = "\c@\ca\cz\o{1}-abc\x{ 1A }";
$ldel =~ tr'\x{0}-\x1a''d;
assert($ldel eq "\c@\ca\cz\o{1}bc\x1a");

$ldel = "\c@\ca\cz\o{1}-abc\x{ 1A }";
$ldel =~ tr/\N{LATIN SMALL LETTER A}-//d;
assert($ldel eq "\c@\ca\cz\o{1}bc\x1a");

$ldel = "\c@\ca\cz\o{1}-abc\x{ 1A }";
$ldel =~ tr/\N{U+0}-\N{U+1a}//d;
assert($ldel eq "-abc");

# tests for issue s27:
#
my $fd = 'c:\\users\\user';
$fd =~ tr{\\}(/);
assert($fd eq 'c:/users/user');

$fd = 'c:\\users\\user';
$fd =~ tr'\\'/';
assert($fd eq 'c:/users/user');

print "$0 - test passed!\n";
