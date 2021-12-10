# issue 93: Expression or return generates bad code
use Carp::Assert;
sub zero
{
    $arg = shift;
    return ($arg == 0);
}

sub zelement
{
    $arg = shift;
    my @result = ();
    push @result, $arg if(!$arg);
    return \@result;
}

zero(0) or assert(0);
zero(0) || assert(0);
@{zelement(0)} or assert(0);

my $val = 0;
zero(1) or $val++;
assert($val == 1);
zero(1) || $val++;
assert($val == 2);
zero(0) and $val++;
assert($val == 3);
zero(0) && $val++;
assert($val == 4);
zero(1) and $val++;
assert($val == 4);
zero(1) && $val++;
assert($val == 4);

my $iterations = 0;
for(my $i=0; $i<3; $i++) {
    $iterations++;
    my $j = zero($i) or last;
    assert($i == 0 && $j == 1);
}
assert($iterations == 2);

$iterations = 0;
for(my $i=0; $i<3; $i++) {
    $iterations++;
    my @arr = @{zelement($i)} or last;
    assert($i == 0 && scalar(@arr) == 1);
}
assert($iterations == 2);

$iterations = 0;
for(my $i=0; $i<3; $i++) {
    $iterations++;
    my $j = zero($i) || last;
    assert($i == 0 && $j == 1);
}
assert($iterations == 2);

$iterations = 0;
for(my $i=0; $i<3; $i++) {
    $iterations++;
    my $j = zero($i) or next;
    assert($i == 0 && $j == 1);
}
assert($iterations == 3);

$iters = 0;
sub check_sub
{
    for(my $i=0; $i<3; $i++) {
        $iters++;
        my $j = zero($i) or return 4;
        assert($i == 0 && $j == 1);
    }
}

assert(check_sub() == 4);
assert($iters == 2);
print "$0 - test passed!\n";
