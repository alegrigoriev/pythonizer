# issue 116 - Statement with both a bash-style "and" and a trailing "if" generates wrong code.

use Carp::Assert;

my $cnt = 1;

go_outside() and play() unless $is_raining;
assert($cnt == 3);

$is_raining = 1;
go_outside() and play() unless $is_raining;
assert($cnt == 3);

sub go_outside {
	$cnt++;
}

sub play {
	$cnt++;
}

print "$0 - test passed!\n";
