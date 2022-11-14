# issue s146 - for loop that starts by incrementing the loop counter is not handled
#
use Carp::Assert;

my $i = 0;
my @lineArr = (0, 1, 2, 3);
my $tot = 0;
for ( $i++; $i <= $#lineArr; $i++ ) {
    assert($i != 0);
    assert($lineArr[$i] == $i);
    $tot++;
}
assert($tot == 3);

# Let's try the other 3 cases
$i = 0;
$tot = 0;
for ( ++$i; $i <= $#lineArr; $i++ ) {
    assert($i != 0);
    assert($lineArr[$i] == $i);
    $tot++;
}
assert($tot == 3);

$i = 2;
$tot = 0;
for ( $i--; $i <= $#lineArr; $i++ ) {
    assert($i != 0);
    assert($lineArr[$i] == $i);
    $tot++;
}
assert($tot == 3);

$i = 2;
$tot = 0;
for ( --$i; $i <= $#lineArr; $i++ ) {
    assert($i != 0);
    assert($lineArr[$i] == $i);
    $tot++;
}
assert($tot == 3);

my $j = 0;
$tot = 0;
for ( $i=$j+1; $i <= $#lineArr; $i++ ) {
    assert($i != 0);
    assert($lineArr[$i] == $i);
    $tot++;
}
assert($tot == 3);

print "$0 - test passed\n";
