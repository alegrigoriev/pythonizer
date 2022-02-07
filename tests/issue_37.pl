# issue 37: Handle scalar context
use Carp::Assert;
my @z = (this, that, those);
$x = @z;
assert($x == 3);
my $m = @z;
assert($m == 3);
$x = localtime();
assert($x =~ /[A-Z][a-z][a-z] [A-Z][a-z][a-z]\s+\d+ \d\d:\d\d:\d\d \d\d\d\d/);
my $y = localtime();
assert($y =~ /[A-Z][a-z][a-z] [A-Z][a-z][a-z]\s+\d+ \d\d:\d\d:\d\d \d\d\d\d/);
@arr = ('');
$arr[0] = localtime();
assert($arr[0] =~ /[A-Z][a-z][a-z] [A-Z][a-z][a-z]\s+\d+ \d\d:\d\d:\d\d \d\d\d\d/);
%hash = ();
$hash{key} = localtime();
assert($hash{key} =~ /[A-Z][a-z][a-z] [A-Z][a-z][a-z]\s+\d+ \d\d:\d\d:\d\d \d\d\d\d/);
$y = 3 + @z;
assert($y == 6);
$y = @z - 1;
assert($y == 2);
$bl = @z > 3;
assert(!$bl);
$bl = 3 <= @z;
assert($bl);
$s = "Z has " . @z . " elements";
assert($s eq 'Z has 3 elements');
$t = "At the tone, the time will be " . localtime();
assert($t =~ /At the tone, the time will be [A-Z][a-z][a-z] [A-Z][a-z][a-z]\s+\d+ \d\d:\d\d:\d\d \d\d\d\d/);
assert(scalar localtime() =~ /[A-Z][a-z][a-z] [A-Z][a-z][a-z]\s+\d+ \d\d:\d\d:\d\d \d\d\d\d/);
#say STDOUT scalar @z;
#say STDOUT scalar localtime();
if(!@z) {
	assert(0);
}
my @e = ();
if(@e) {
	assert(0);
}
# Let's try some "comma" operators
$x = 5, 4;
assert($x == 5);        # '=' is higher precedence than ','
$x = (6, 5);
assert($x == 5);
$y = ($x = 8, 9);
assert($x == 8 && $y == 9);
$x = (6, 5, 4);
assert($x == 4);
$gotHere = 0;
if(14, 0) {
    assert(0);
} else {
    $gotHere = 1;
}
assert($gotHere);
$gotHere = 0;
my $zero = 0;
if(0) {
    assert(0);
}elsif($x=12, $y++, $zero) {
    assert(0);
} else {
    $gotHere = 1;
}
assert($x == 12);
assert($y == 10);
assert(!$zero);
assert($gotHere);
my $k = 3;
my $cnt = 0;
while($x = $k, $k--) {
    $cnt++;
}
assert($x == 0);
assert($k == -1);
assert($cnt == 3);
$y = (72, 77, 78, localtime());
assert($y =~ /[A-Z][a-z][a-z] [A-Z][a-z][a-z]\s+\d+ \d\d:\d\d:\d\d \d\d\d\d/);
$x = (14, 32, @z);
assert($x == 3);
$x = (@z);
assert($x == 3);

# from here down is list context
my @n = @z;
assert($n[0] eq $z[0] && $n[1] eq $z[1] && $n[2] eq $z[2]);
($aa, $bb, $cc) = @z;
assert($aa eq $z[0] && $bb eq $z[1] && $cc eq $z[2]);
($dd) = @z;
assert($dd eq $z[0]);
my @l = localtime();
assert(@l == 9);
my $l = () = localtime();
assert($l == 9);

sub mysub
{
    assert(@_ == 9);
    return 1;
}

my $r = mysub(localtime());
assert($r == 1);
#say STDOUT @l;
#say STDOUT localtime();
print "$0 - test passed!\n";
