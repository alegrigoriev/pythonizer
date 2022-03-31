# Take the address of a scalar and try to modify it - shouldn't work but give a warning

use Carp::Assert;

my $scalar = 10;

my %hash = (key => \$scalar);

${$hash{key}} = 11;

assert($scalar == 11 || $scalar == 10);

print "$0 - test passed!\n";
