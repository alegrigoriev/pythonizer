# issue s65 - x operator always converts it's left operand to a string
use Carp::Assert;
no warnings 'experimental';

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

sub is_multiple_of {
    my ($mul, $arr, $i) = @_;
    my $arr_len = scalar @$arr;
    my $mul_len = scalar @$mul;

    return 0 if $mul_len != $arr_len * $i;

    for (my $mul_idx = 0; $mul_idx < $mul_len; $mul_idx++) {
        my $arr_idx = $mul_idx % $arr_len;
        return 0 if $mul->[$mul_idx] != $arr->[$arr_idx];
    }

    return 1;
}

my @arr = (1,2,3);
for(my $i = 0; $i <= 10; $i++) {
    my @mul = (@arr) x $i;

    assert(is_multiple_of(\@mul, \@arr, $i), "@mul is not @arr x $i");
}

print "$0 - test passed!\n";
