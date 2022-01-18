# Test array index assignment used in an expression
use Carp::Assert;

my @arr = (1,2);
assert($arr[0] == 1 && $arr[1] == 2);
my $c = 0;
if($arr[0] = 2) {
    assert($arr[0] == 2);
    $c++;
}
assert($arr[0] == 2);
assert($c == 1);
if($arr[0] = 0) {       # Should be false but set the array element
    ;
} elsif($arr[0] += 3) { # True and add to the array element
    $c++;
}
assert($arr[0] == 3);
assert($c == 2);
my $i = 1;
assert(($arr[$i] -= 1) == 1);
assert(($arr[$i-1] *= 4) == 12);
assert($arr[$i-1] == 12);
while(($arr[$i-1] /= 6) > 1) {
    $c++;
}
assert($c == 3);
assert($arr[--$i] < 0.34 && $arr[$i] > 0.33);
my %hash = (k0=>0, k1=>1, k2=>2, word=>'word');
assert(2**3 == 8);
assert(($hash{k2} **= 3) == 8);
assert($hash{k2} == 8);
assert(($hash{word} .= 'up') eq 'wordup');
assert($hash{word} eq 'wordup');
assert(($hash{k2} %= 2) == 0);
assert($hash{k2} == 0);
assert(($hash{k2} += 2) == 2);
assert($hash{k2} == 2);
assert(($hash{k2} ^= 2) == 0);
assert($hash{k2} == 0);
my $key = 'k2';
assert(3 == ($hash{$key} |= 3));
assert($hash{$key} == 3);
assert(($hash{$key} &= 2) == 2);
assert($hash{$key} == 2);
assert((2<<1) == 4);
assert(($hash{k2} <<= 1) == 4);
assert($hash{k2} == 4);
assert((4>>1) == 2);
assert(($hash{k2} >>= 2) == 1);
assert($hash{k2} == 1);

print "$0 - test passed!\n";


