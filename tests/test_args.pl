# Test a variety of subs with args

use Carp::Assert;

sub noargs { return "noargs"; }
assert(noargs eq "noargs");

sub oneargshift
{
    my $arg = shift;

    return $arg;
}
assert(oneargshift(12) == 12);

sub oneargindex
{
    my $arg = $_[0];

    return $arg;
}
assert(oneargindex(13) == 13);

sub twoargsshift
{
    my $arg1 = shift;
    my $arg2 = shift;

    $arg1 / $arg2;
}
assert(twoargsshift(10,5) == 2);

sub twoargsindex
{
    my $arg1 = $_[0];
    my $arg2 = $_[1];
    $arg1 / $arg2;
}
assert(twoargsindex(10,2) == 5);

sub twoargsindexunnamed
{
    $_[0] / $_[1];
}
assert(twoargsindexunnamed(20,2) == 10);

sub oneargoneoptionalshift
{
    my $arg1 = shift;
    my $arg2;
    $arg2 = shift if(@_);

    return $arg1 if(!defined $arg2);
    $arg1 + $arg2;
}

assert(oneargoneoptionalshift(4) == 4);
assert(oneargoneoptionalshift(4,2) == 6);


sub oneargoneoptionalindex
{
    my $arg1 = $_[0];
    my $arg2;
    $arg2 = $_[1] if(@_ >= 2);

    return $arg1 if(!defined $arg2);
    $arg1 + $arg2;
}

assert(oneargoneoptionalindex(4) == 4);
assert(oneargoneoptionalindex(4,2) == 6);

sub maxit
{
    my $result = $_[0];
    foreach $val (@_[1..$#_]) {
        $result = ($result > $val) ? $result : $val;
    }
    return $result;
}

assert(maxit(1) == 1);
assert(maxit(3,2,1) == 3);
assert(maxit(-3,-4,0) == 0);
@arr = (3,4,7,19,2,42,-1,3);
assert(maxit(@arr) == 42);

print "$0 - test passed!\n";

