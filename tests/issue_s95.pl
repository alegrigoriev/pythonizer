# issue s95 - local %hash creates an Array instead
use Carp::Assert;

sub test {
    local %hash = ();
    local (%h1, %h2) = ();
    local @arr = ();
    local (@a1, @a2) = ();
    local ($s1, $s2) = (1, 2);

    $hash{k1}{k2} = 'value';
    assert($hash{k1}{k2} eq 'value');

    $h1{k1} = 'v';
    $h2{v1} = 'k1';
    assert($h1{$h2{v1}} eq 'v');

    $arr[0][0] = 1;
    assert(scalar(@arr) == 1);
    assert($arr[0][0] == 1);

    $a1[0] = 4;
    $a2[4] = 3;
    assert($a2[$a1[0]] == 3);

    assert($s1 == 1);
    assert($s2 == 2);
}

test();
assert(scalar(%hash) == 0);
assert(scalar(%h1) == 0);
assert(scalar(%h2) == 0);
assert(scalar(@arr) == 0);
assert(scalar(@a1) == 0);
assert(scalar(@a2) == 0);
assert(!defined $s1);
assert(!defined $s2);

print "$0 - test passed\n";
