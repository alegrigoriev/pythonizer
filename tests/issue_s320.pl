# issue s320 - Defining a sub with a fully qualified package name generates bad code
use Carp::Assert;

sub main::mySub { 1 }

assert(main::mySub() == 1);

sub ABC::DEF::ghi { 2 };
assert(ABC::DEF::ghi == 2);

print "$0 - test passed!\n";
    
