# issue 67 - Open generates an empty argument when trying to open an expression instead of a scalar

use Carp::Assert;

my $dir = '.';
# pragma pythonizer no pl_to_py, no replace usage
my $file = "issue_67.pl";
open(FY, $dir.'/'.$file);
my $line = <FY>;
assert($line =~ /issue 67/);
close(FY);
print "$0 - test passed!\n";
