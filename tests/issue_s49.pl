# issue with continue in while loop from pl_associate.pl
use Carp::Assert;
$cnt1=$cnt2=$cnt3 = 0;
MAIN_LOOP:
while($i++ < 20) {
	$cnt1++;
	if($i == 3) {
		$i++;
		redo;
	}

	$number = 3;
	while($number) {
		$cnt2++;
		next MAIN_LOOP if $number == 2;
	} continue {
		$number--;
	}

	$cnt3++;

}

assert($cnt1 == 20);
assert($cnt2 == 38);
assert($cnt3 == 0);

print "$0 - test passed!\n";
