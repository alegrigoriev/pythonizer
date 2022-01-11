# issue 95 - Bad code generated if last statement in block before else or elsif doesn't end in ;
use Carp::Assert;

my $t = 1;
if($t == 1) {
    $t = 2
}
assert($t == 2);

my $ctr = 0;
for $i (0..5) {
    {
        $ctr++
    }
    if($i == 0) {
        next
    } elsif(0) {
        next
    } else {
        last
    }
}
assert($ctr == 2);

$g = 0;
sub func
{
    $g = 14
}

if($t == 2) {
    func
}
{
    assert($g == 14)
}
assert($g == 14);

do {
    $g++
} until($g == 16);
assert($g == 16);

do {
    $g++
} while($g == 20);
assert($g == 17);
$ctr = 0;
do {
    $g++
};
while($g < 20) {
    $g++;
    $ctr++
}
assert($g == 20);
assert($ctr == 2);

$hell_freezes_over = 0;
looper:{
    do {
        $g++;
        last if($ctr == 2)
    } until($hell_freezes_over);
}
assert($g == 21);

$i = 0;
do {
    $i++;
    $g++
} unless $g < 0;
assert($i == 1);
assert($g == 22);

do {
    $i++;
    $g++
} if $i > 0;
assert($i == 2);
assert($g == 23);

do {
    $i++;
    $g++
} if $i < 0;
assert($i == 2);
assert($g == 23);

print "$0 - test passed!\n";
