# issue s32 - Implement utime function
use Carp::Assert;

open($fh, '>tmp.tmp');
open(FD, '>tmp2.tmp');
close(FD);

for my $fd ($fh, 'tmp2.tmp') {
	$now = time();
	$before = $now - 60*60*24;
	$earlier = $before - 60*60*24;
	$count = utime($before, $earlier, $fd, "not_found");
	assert($count == 1);
	assert($!);
	$eps = 1.2/(60*60*24);
	assert((abs((-M $fd)-2)) < $eps);
	assert((abs((-A $fd)-1)) < $eps);
	assert(!-f "not_found");
}

print "$0 - test passed!\n";

END {
    eval {close($fh)};
    eval {unlink "tmp.tmp"};
    eval {unlink "tmp2.tmp"};
}

