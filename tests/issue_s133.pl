# issue 133 - Interpret use lib "$FindBin::Bin"
use Carp::Assert;
use FindBin;
use lib "$FindBin::Bin/subdir";
#use lib $FindBin::Bin;
use FindMe;

assert($findme);

print "$0 - test passed!\n";
