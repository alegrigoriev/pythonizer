# issue s12 - return from BEGIN should exit the block

use Carp::Assert;

BEGIN {
	$i = 0;
	return;
	$i = 1;
}

INIT {
	assert($i == 0);
	$i = 2 and return;
	$i = 3;
}
assert($i == 2);

END {
	assert($i == 2);
	assert($j == 2);
	print "$0 - test passed!\n";
}

END {
	$j = 2;
	return;
	$j = 3;
}

