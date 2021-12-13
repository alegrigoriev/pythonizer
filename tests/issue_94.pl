# issue 94: next or last not in a loop
use Carp::Assert;

$v1 = 1;
$v2 = 2;
{
    next if($v1 == 1);
    $v1 = 2;
}
assert($v1 == 1);
{
    last if($v1 == 1);
    $v1 = 2;
}
assert($v1 == 1);

if($v1 == 1) {
    {
        next if($v2 == 2);
        $v1 = 2;
    }
}
assert($v1 == 1);
if($v1 == 2) {
    $v1 = 3;
} else {
    {
        last if($v2 == 2);
        $v1 = 2;
    }
}
assert($v1 == 1);
for $i (0..10) {
    if($v1 == 1) {
        last;
    }
}
assert($i == 0);

sub subr
{
    last;               # Should break out of loop in caller (really!)
    $v1 = 2;
}

for $i (0..10) {
    $j = $i;
    subr();

}
assert($j == 0);
assert($v1 == 1);

outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        next outer if($v1 == 1);
        $v1 = 2;
    }
}
assert($ii == 10 && $jj == 0 && $v1 == 1);

outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        last outer if($v1 == 1);
        $v1 = 2;
    }
}
assert($ii == 0 && $jj == 0 && $v1 == 1);

outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        next inner if($v1 == 1);
        $v1 = 2;
    }
}
assert($ii == 10 && $jj == 10 && $v1 == 1);

outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        last inner if($v1 == 1);
        $v1 = 2;
    }
}
assert($ii == 10 && $jj == 0 && $v1 == 1);

sub sub2
{
    if($v1 == 1) {
        next outer;               # Should 'next outer' the loop in caller (really!)
    }
    $v1 = 2;
}

outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        sub2() if($v1 == 1);
    }
}
assert($ii == 10 && $jj == 0 && $v1 == 1);

sub sub3
{
    outer: for $k (0..10) {
        $kk = $k;
        last outer;               # Should NOT 'last outer' the loop in caller
        $v1 = 2;
    }
    assert($kk == 0 && $v1 == 1);

}

outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        sub3() if($v1 == 1);
        $v2 = 10;
    }
}
assert($ii == 10 && $jj == 10 && $v1 == 1 && $v2 == 10);

sub sub4
{
    outer: for $k (0..10) {
        $kk = $k;
        next outer;               # Should NOT 'next outer' the loop in caller
        $v1 = 2;
    }
    assert($kk == 10 && $v1 == 1);

}

$v2 = 2;
outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        sub4() if($v1 == 1);
        last outer;             # Should last our outer, not the one in sub4
        $v2 = 10;
    }
}
assert($ii == 0 && $jj == 0 && $v1 == 1 && $v2 == 2);

sub sub5
{
    inner: for $k (0..10) {
        $kk = $k;
        last outer if($v1 == 1);               # Should 'last outer' the loop in caller
        $v1 = 2;
    }
    assert(0);                  # Shouldn't get here

}

outer: for $i (0..10) {
    $ii = $i;
    inner: for $j (0..10) {
        $jj = $j;
        sub5() if($v1 == 1);
        $v2 = 10;
    }
}
assert($ii == 0 && $jj == 0 && $v1 == 1 && $v2 == 2);

sub sub6
{
    last if($v1 == 1);
}
eval {
    sub6();
};
assert($@ =~ /outside a loop block/ or $@ =~ /break/);

print("$0 - test passed!\n");
