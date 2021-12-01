# issue 13: Handle scalar context
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

# from here down is list context
my @n = @z;
assert($n[0] eq $z[0] && $n[1] eq $z[1] && $n[2] eq $z[2]);
($aa, $bb, $cc) = @z;
assert($aa eq $z[0] && $bb eq $z[1] && $cc eq $z[2]);
($dd) = @z;
assert($dd eq $z[0]);
my @l = localtime();
assert(@l == 9);
#say STDOUT @l;
#say STDOUT localtime();
print "$0 - test passed!\n";
