# issue s128 - Implement FindBin
use Carp::Assert;


#
# Tests adapted from the official perl test suite:
#

use FindBin qw($Bin);

#print "$Bin\n";
assert( $Bin =~ m,tests$, );

my $zero = $0;

$0 = "-";
FindBin::again();

assert( $FindBin::Script eq "-" );

# more tests

$0 = $zero;
FindBin::again();

use FindBin qw(:ALL);

#print "$Script, $RealBin, $RealScript, $Dir, $RealDir\n";
assert($Script =~ /issue_s128/);
assert($RealBin eq $Bin);
assert($RealScript eq $Script);
assert($Dir =~ /tests$/);
assert($RealDir eq $Dir);

print "$0 - test passed\n";
