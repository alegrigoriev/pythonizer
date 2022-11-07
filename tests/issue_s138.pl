# issue s138 - Split on '\|' doesn't work properly
use Carp::Assert;

my $s = 'a|b|c';
my @a = split('\|', $s);
assert(@a == 3);
assert(join(' ', @a) eq 'a b c');

my @b = split("\|", $s);
assert(@b == 5);
assert($b[0] eq 'a');
assert(join(' ', @b) eq 'a | b | c');

my @c = split(/\|/, $s);
assert(@c == 3);
assert(join(' ', @c) eq 'a b c');

my @A = split '\|', $s;
assert(@A == 3);
assert(join(' ', @A) eq 'a b c');

my @B = split 'b', $s;
assert(@B == 2);
assert($B[0] eq 'a|');
assert($B[1] eq '|c');

print "$0 - test passed!\n";
