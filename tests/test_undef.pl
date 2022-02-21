# test the undef function in various places
use Carp::Assert;

$a = undef;
$b = $c = undef;

$a++;
$c += 1;

assert($a == 1);
assert(!defined $b);
assert($c == 1);

my $m = undef;
assert(!defined $m);

my $n = undef;
$n++;
assert($n == 1);

my ($o, $p);
$o++;
assert(!defined $p);

my ($q, $r) = (undef, undef);
$q++;
$r--;
assert($q == 1);
assert($r == -1);

my ($s, $t) = ();
$s++;
assert($s == 1);
assert(!defined $t);

(undef, undef, $d) = (7, 5, 10);
assert($d == 10);

($e, undef, undef) = (undef, 42, 37);
assert(!defined $e);

print "$0 - test passed!\n";
