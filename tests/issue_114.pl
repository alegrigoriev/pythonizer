# issue 114: substr with replacement

use Carp::Assert;

my $s = "The black cat climbed the green tree";
my $cl = substr $s, 14, 7;
assert($cl eq 'climbed');
my $t = $s;
substr($t, 14, 7) = "jumped from";
assert($t eq "The black cat jumped from the green tree");

my $u = $s;
substr $u, 14, 7, "jumped from";
assert($u eq "The black cat jumped from the green tree");

my $v = $s;
substr($v, 14, 7, "jumped from");
assert($v eq "The black cat jumped from the green tree");

my $z = substr $s, 14, 7, "jumped from";    # climbed

assert($z eq 'climbed');
assert($s eq "The black cat jumped from the green tree");

print "$0 - test passed!\n";
