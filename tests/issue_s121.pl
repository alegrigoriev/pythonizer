# issue s121 - localtime, gmtime, and timelocal shouldn't raise exceptions
use Carp::Assert;
use Time::Local;

my @tests = (99999999999, 39, 46, 9, 16, 10, 3238, 3, 319, 0,
	     2147483647, 7, 14, 3, 19, 0, 138, 2, 18, 0,
	     -9999999, 21, 13, 6, 7, 8, 69, 0, 249, 0,
	     100, 40, 1, 0, 1, 0, 70, 4, 0, 0);


for($i=0; $i < scalar(@tests); $i+=10) {
	my @p = gmtime($tests[$i]);
	for($j=1; $j < 10; $j++) {
		#print "$i, $tests[$i], $j, $p[$j-1], $tests[$i+$j]\n";
		assert($p[$j-1] == $tests[$i+$j]);
	}
	my $g = timegm(@p);
	@q = localtime($tests[$i]);
	assert($q[0] == $p[0]);	# sec
	assert($q[1] == $p[1]);	# min
	my $l = timelocal(@q);
	#print "$l\n";
	#assert($l == $tests[$i]);
}

# Try crazy values and make sure it doesn't crash
my @d = gmtime(99999999999999999);
@d = localtime(99999999999999999);
my $x = timelocal(@d);

print "$0 - test passed\n";
