# issue s65 - x operator always converts it's left operand to a string
use Carp::Assert;

assert('s' x 5 eq 'sssss');

$num_frames = 3;
@ram = ((-1) x $num_frames);

assert(@ram == 3);
foreach (@ram) {
	assert($_ == -1);
}

@ram = (-2) x $num_frames;

assert(@ram == 3);
foreach (@ram) {
	assert($_ == -2);
}

@strs = qw/a b c/ x 2;
assert(@strs == 6);
assert($strs[0] eq 'a');
assert($strs[1] eq 'b');
assert($strs[2] eq 'c');
assert($strs[3] eq 'a');
assert($strs[4] eq 'b');
assert($strs[5] eq 'c');

print "$0 - test passed!\n";
