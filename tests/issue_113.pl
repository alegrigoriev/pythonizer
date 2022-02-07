# issue 113 - Bad code is generated if you use a single quote as a substitution delimiter

use Carp::Assert;

my $var = 'abc';
$var =~ s'abc'def';
assert($var eq 'def');

print "$0 - test passed!\n";
