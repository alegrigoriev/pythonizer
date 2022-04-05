# issue s31 - Assignment to typeglob with a variable name doesn't generate any code
use Carp::Assert;

my $field = "UNIX";
$_ = "UNIX";

*{"_IS_$_"} = $field eq $_ ? sub () { 1 } : sub () { 0 };

assert(_IS_UNIX() == 1);

print "$0 - test passed!\n";
