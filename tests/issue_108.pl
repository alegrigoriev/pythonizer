# issue_108: Implement local
use Carp::Assert;

$local = 'abc';
@local = ('a', 'b', 'c');
%local = (k1=>'v1');
assert($local eq 'abc');
assert($local[0] eq 'a');
assert($local{k1} eq 'v1');

sub getLocals
{
    return ($local, \@local, \%local);
}

sub testLocal
{
    local *local;

    assert(!defined $local);
    assert(!@local);
    assert(!%local);

    $local = 'def';
    @local = ('d', 'e', 'f');
    %local = (k2=>'v2');

    assert($local eq 'def');
    assert($local[0] eq 'd');
    assert($local{k2} eq 'v2');

    ($v, $a, $h) = getLocals();

    assert($v eq 'def');
    assert($a->[0] eq 'd');
    assert($h->{k2} eq 'v2');
}

testLocal();

assert($local eq 'abc');
assert($local[0] eq 'a');
assert($local{k1} eq 'v1');

sub subtest
{
    assert($arg eq 14);
}

sub testLocal2
{
    local $arg = shift;
    local ($i, $j, $k) = (7,7,7);
    assert($i == 7 && $j == 7 && $k == 7);
    subtest();
    return $arg;
}

assert(!defined $arg);
assert(testLocal2(14) == 14);
assert(!defined $arg);

print "$0 - test passed!\n";
