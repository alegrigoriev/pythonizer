# issue s69 - Hex constant in source code generates internal warning message and gets changed to 0
use Carp::Assert;

sub and_ffff
{
    my $arg = shift;
    return $arg & 0xffff;
}

sub and_777
{
    my $arg = shift;

    return $arg & 0777;
}

assert(and_ffff(0xfffff) == 65535);
assert(and_777(07777) == 511);
assert(cos(0) == 1);
assert(cos(0x0) == 1);
assert(cos(00) == 1);
assert(cos(3) == cos(0x3));
assert(cos(3) == cos(03));

my @arr = (0,1,2);
assert($arr[1.1] == 1);

print "$0 - test passed!\n";
