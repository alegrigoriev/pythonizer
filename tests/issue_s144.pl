# issue s144 - my statement with a comma-separated list of initializations generates bad code
#pragma pythonizer -M
use Carp::Assert;
use feature 'state';
my $l2ccifname="", $l2vccid="", $l2des="" ;     # Only the first name is 'my', the rest are global

assert($l2ccifname eq '');
assert($l2vccid eq '');
assert($l2des eq '');
assert(!defined $::l2ccifname);
assert(defined $::l2vccid);
assert(defined $main::l2des);

my $chA, $chB = "b", $chC = 'c', $chX;

assert($chA eq '');
assert($chB eq 'b');
assert($chC eq 'c');
assert($chX eq '');
assert($::chC eq 'c');
assert($::chX eq '');

my @ar1 = (1, 2), @ar2 = (2, 3, 4), @ar3;

assert(@ar1 == 2);
assert(join('',@ar1) eq '12');
assert(@main::ar1 == 0);

assert(@ar2 == 3);
assert(join('',@ar2) == 234);
assert(@main::ar2 == 3);

assert(@ar3 == 0);
assert(@main::ar3 == 0);

$s = 1, $t = 2;

sub mysub {
    my $s, $t;      # Only $s is a 'my' variable at this point!
    return $s . $t;
}
my $res = mysub();
assert($res eq '2');

$l1 = 0;
$l2 = 1;
$l3 = 2;
sub tryLocal {
    local $l1 = 1, $l2 = 2, $l3;        # In this case, they are all local
    assert($l1 == 1);
    assert($l2 == 2);
    assert($l3 == 2);
    $l3 = 4;

    return $l1 + $l2 * $l3;
}
assert($l1 == 0);
assert($l2 == 1);
assert($l3 == 2);

assert(tryLocal() == 9);

sub tryState {
    state $s=3, $t=4;               # Only the first one is 'state'

    return ($s++) + ($t--);
}
for(my $i = 7; $i < 15; $i++) {
    assert(tryState() == $i);
    assert($s == 1);
    assert($t == 3);
}

print "$0 - test passed!\n";
