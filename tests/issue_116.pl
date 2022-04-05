# issue 116 - Statement with both a bash-style "and" and a trailing "if" generates wrong code.

use Carp::Assert;

my $cnt = 1;

go_outside() and play() unless $is_raining;
assert($cnt == 3);

go_outside(), play() unless $is_raining;
assert($cnt == 5);

$is_raining = 1;
go_outside() and play() unless $is_raining;
assert($cnt == 5);

go_outside() 
	and play() 
		unless $is_raining;
assert($cnt == 5);

wear_a_hat() or take_the_umbrella() if $is_raining;
assert($cnt == 6);

wear_a_hat() 
	or take_the_umbrella() 
		if $is_raining;
assert($cnt == 7);

do_nothing() or take_the_umbrella() if $is_raining;
assert($cnt == 9);

$is_raining = 0;
wear_a_hat() or take_the_umbrella() if $is_raining;
assert($cnt == 9);

go_outside() and play();
assert($cnt == 11);

go_outside(), play();
assert($cnt == 13);

wear_a_hat() or take_the_umbrella();
assert($cnt == 14);

do_nothing() or take_the_umbrella();
assert($cnt == 16);

$cnt += 1 and $cnt += 3;
assert($cnt == 20);

$cnt += 2, $cnt += 3;
assert($cnt == 25);

$cnt += 5 or $cnt += 3;
assert($cnt == 30);

$cnt += 2 and $cnt += 3 if $is_raining;
assert($cnt == 30);

# issue s35:
go_outside() and do {$cnt++; play(); take_the_umbrella()};
assert($cnt == 35);

go_outside() and do {$cnt++; play() and take_the_umbrella()};
assert($cnt == 40);

go_outside() and do {$cnt++; play() or take_the_umbrella()};
assert($cnt == 43);

sub go_outside {
	$cnt++;
}

sub play {
	$cnt++;
}

sub wear_a_hat {
	$cnt++;
}

sub take_the_umbrella {
	$cnt += 2;
}

sub do_nothing { 0 }

print "$0 - test passed!\n";
