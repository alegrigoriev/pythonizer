# issue s52 - 3-arg split generates incorrect code

use Carp::Assert;
use Data::Dumper;

sub splitdir {
    return split m|/|, $_[1], -1;  # Preserve trailing fields
}

my $dir = "/c/pythonizer/pythonizer/tests/";
my @d = splitdir('File::Spec', $dir);
assert(scalar(@d) == 6);
assert(join(' ', @d) eq ' c pythonizer pythonizer tests ');

# test some other cases of split

$_ = "  Quick Brown fox\n";
assert(split == 3);     # same as assert(split(' ', $_, 0) == 3)

my @q = split qr/b/i;
assert(@q == 2);
assert($q[0] eq '  Quick ');
assert($q[1] eq "rown fox\n");

my @r = split m'b'i;
assert(@r == 2);
assert($r[0] eq '  Quick ');
assert($r[1] eq "rown fox\n");

my @s = split /b/i;
assert(@s == 2);
assert($s[0] eq '  Quick ');
assert($s[1] eq "rown fox\n");

print "$0 - test passed!\n";
