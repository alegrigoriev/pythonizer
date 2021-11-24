use Carp::Assert;
@ar = (1, 2, 3);
$i = pop @ar;
assert($i == 3);
assert(@ar == 2 && $ar[0] == 1 && $ar[1] == 2);
assert(pop @ar == 2);
assert(@ar == 1 && $ar[0] == 1);
assert(pop @ar == 1);
assert(@ar == 0);
sub check_pop
{
	$j = pop;
	assert($j == 3);
	assert(scalar(@_) == 2);
	assert(pop == 2);
	assert(scalar(@_) == 1);
}
check_pop(1, 2, 3);
print "$0 - test passed!\n";
