# issue s160 - Assignment to @hash{@keys} generates bad code
# pragma pythonizer -M
use Carp::Assert;

@typearray = ();
#@typearray = ('a', 'b', 'b', 'c');
my @tya = ('a', 'b', 'b', 'c');
foreach (@tya) {
    push @typearray, $_;
}
# Eliminate duplicate types and models
undef %unique;
@unique{@typearray}={};
@typearray = keys %unique;
@typearray = sort @typearray;

assert(@typearray == 3);
assert($typearray[0] eq 'a');
assert($typearray[1] eq 'b');
assert($typearray[2] eq 'c');

my @ta = ('a', 'b', 'b', 'c');
# Eliminate duplicate types and models
undef %unique;
@unique{@ta}={};
@ta = keys %unique;
@ta = sort @ta;

assert(@ta == 3);
assert($ta[0] eq 'a');
assert($ta[1] eq 'b');
assert($ta[2] eq 'c');

print "$0 - test passed!\n";

