# test if we parse concat operator '.' properly if it has digits following it
# inspired by https://github.com/Perl-Critic/PPI/issues/165
use Carp::Assert;

$flt = .125;
assert($flt == 0.125);

$str = "a".125;
assert($str eq 'a125');

$str = $str.6;
assert($str eq 'a1256');

$str = ($str).7;
assert($str eq 'a12567');

$hash{key} = '8';

$hash{key} = $hash{key}.9;

assert($hash{key} eq '89');

$arr[0] = '0';
$arr[0] = $arr[0].1;
assert($arr[0] eq '01');

print "$0 - test passed!\n";
