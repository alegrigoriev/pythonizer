# issue s211 - ModuleNotFoundError: No module named 'CGI.Util'; 'CGI' is not a package
use lib '.';
use subdir;
use subdir::subsubdir::utils qw/myutil/;
use otherdir::othermod qw/otherfunc/;
use Carp::Assert;

my $s = new subdir;
assert($s->identity(2) == 2);

assert(myutil(1) == 2);
assert(otherfunc(2) == 1);

print "$0 - test passed!\n";
