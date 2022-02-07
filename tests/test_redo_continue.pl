# Test redo and continue
use Carp::Assert;

$i = 5;
$j = 3;
my ($ctr1, $ctr2, $ctr3, $ctr4);
while($i--) {
	$ctr1++;
	redo if($j-- == 2);
	next if $i == 2;
	last if $i == 1;
	$ctr2++;
} continue {
	$ctr3++;
	last if $j == 0;
	$ctr4++;
}
#print "$i, $j, $ctr1, $ctr2, $ctr3, $ctr4\n";
assert($i == 3);
assert($j == 0);
assert($ctr1 == 3);
assert($ctr2 == 2);
assert($ctr3 == 2);
assert($ctr4 == 1);

$i = 6;
$ctr1=$ctr2=$ctr3=$ctr4=$ctr5=0;
OUTER: while(1) {
	$ctr1++;
	INNER: for($j = 0; $j < 5; $j++) {
		$ctr2++;
		#redo OUTER if $ctr1 == 1;
		redo if $ctr2 == 2;
		next OUTER if($j == 2);
		$ctr3++;
	}
} continue {
	$ctr4++;
	#next if($ctr4 == 1);
	#redo if($ctr4 == 2);
	last if(--$i == 0);
	$ctr5++;
}
#print "$i, $j, $ctr1, $ctr2, $ctr3, $ctr4, $ctr5\n";
assert($i == 0);
assert($j == 2);
assert($ctr1 == 6);
assert($ctr2 == 19);
assert($ctr3 == 12);
assert($ctr4 == 6);
assert($ctr5 == 5);

print "$0 - test passed!\n";

