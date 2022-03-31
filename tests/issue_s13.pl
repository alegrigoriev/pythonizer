# issue s13 - $var = eval 'expr'; generates incorrect code
use Carp::Assert;

$i = 0;
sub mysub {
    $i = 1;
}

eval 'mysub()';
assert($i == 1);

sub decr1 {
	$i--;
}
sub decr2 { $i-- }
sub decr2a { 
	$i-- 
}
sub decr3 {
	$i--	# decrement i
}
sub incr1 {
	$i++;
}
sub incr2 { $i++ }
sub incr2a { 
	$i++ 
}
sub incr3 {
	$i++	# increment i
}
sub decr4 {
	--$i;
}
sub decr5 { --$i }
sub decr6 {
	--$i	# pre-decrement i
}
sub incr4 {
	++$i;
}
sub incr5 { ++$i }
sub incr6 {
	++$i	# pre-increment i
}
assert(incr1() == 1 && $i == 2);
assert(decr1() == 2 && $i == 1);
assert(incr2() == 1 && $i == 2);
assert(decr2() == 2 && $i == 1);
assert(incr3() == 1 && $i == 2);
assert(decr3() == 2 && $i == 1);
assert(incr4() == 2 && $i == 2);
assert(decr4() == 1 && $i == 1);
assert(incr5() == 2 && $i == 2);
assert(decr5() == 1 && $i == 1);
assert(incr6() == 2 && $i == 2);
assert(decr6() == 1 && $i == 1);


my $val = eval '$i+1';

assert($val == 2);

$vvv = eval '$i--';
assert($vvv == 1);
assert($i == 0);

$vvv = eval '++$i';
assert($vvv == 1);
assert($i == 1);

$vvv = eval {$i++};
assert($vvv == 1);
assert($i == 2);

# try some with brackets
$hash{key1}{key2} = 0;
$vvv = eval '++$hash{key1}{key2}';
assert($vvv == 1);
assert($hash{key1}{key2} == 1);

sub decrhash { --$hash{key1}{key2} };
assert(decrhash == 0 && $hash{key1}{key2} == 0);

our $Exp;

BEGIN {
	$Exp = eval 'exp(1)';
}

assert($Exp == exp(1));

my $result = eval '0' ||
	     eval '2' ||
	     eval '4';

assert($result == 2);



print "$0 - test passed\n";
