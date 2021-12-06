# Test automatic initialization
use v5.10;
use Carp::Assert;
$j++;
assert($j == 1);
--$i;
assert($i == -1);
$f += 3.5;
assert($f == 3.5);
$s .= 'Hello World!';
assert($s eq 'Hello World!');
$myHash{key} = 'value';
assert($myHash{key} eq 'value');
push @arr, 6;
assert($arr[0] == 6);

sub test
{
    $t++;
    assert($t == 1);

    my $u;
    $u .= 'abc';
    assert($u eq 'abc');

    state $s1 = 0;
    $s1++;
    assert($s1 == 1);

    state $s2;
    ++$s2;
    assert($s2 == 1);
}
test();

print "$0 - test passed!\n";
