# issue 114: substr with replacement

use Carp::Assert;

my $s = "The black cat climbed the green tree";
my $z = substr $s, 14, 7, "jumped from";    # climbed

assert($z eq 'climbed');
assert($s eq "The black cat jumped from the green tree");

print "$0 - test passed!\n";
