# issue s50: next LABEL inside a do {...} generates incorrect code, causing the do to become an infinite loop
use Carp::Assert;

my $ctr1 = $ctr2 = $ctr3 = 0;
OUTER:
while($i++ < 10) {
	$ctr1++;
	my $j = 0 or do {
		$i += 2;
		$ctr2++;
		next OUTER;
	};
	$ctr3++;
}
assert($ctr1 == 4);
assert($ctr2 == 4);
assert($ctr3 == 0);
print "$0 - test passed!\n";
