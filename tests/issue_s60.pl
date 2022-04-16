# issue 60 - If statement following a do {...} gives error messages and generates incorrect code
use Carp::Assert;

do {
	$i++;
	$j++;
};

if($i == 1 && $j == 1) {
	print "$0 - test passed!\n";
} else {
	assert(0);
}
