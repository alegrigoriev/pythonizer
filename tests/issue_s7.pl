# issue s7 - complex expression with '||' messes up the nesting level

use Carp::Assert;

sub wrecks_the_nesting_level
{
    my $arg = shift;
    $arg =~ /(1.*)(2.*)(3.*)/;
    my ($p, $q);
    ($p, $q) = ($1, ($2 eq '-' ? -1 : ($2 || 1)) * pi() / ($3 || 1));
}

my $eps = 1e-10;
my $pi = 3.141592653589793;
@a = wrecks_the_nesting_level("123");
assert($a[0] == 1 && abs($a[1] - ($pi * 2 / 3)) < $eps);

#
# pi
#
# The number defined as pi = 180 degrees
#
sub pi () { 4 * CORE::atan2(1, 1) }

#
# pi2
#
# The full circle
#
sub pi2 () { 2 * pi }

#
# pi4
#
# The full circle twice.
#
sub pi4 () { 4 * pi }

#
# pip2
#
# The quarter circle
#
sub pip2 () { pi / 2 }

#
# pip4
#
# The eighth circle.
#
sub pip4 () { pi / 4 }


assert(abs(pi() - $pi) < $eps);
assert(abs(pi2() - $pi*2) < $eps);
assert(abs(pi4() - $pi*4) < $eps);
assert(abs(pip2() - $pi/2) < $eps);
assert(abs(pip4() - $pi/4) < $eps);

print "$0 - test passed!\n";
