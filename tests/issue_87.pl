# issue 87 - Old perl scripts use ' instead of :: - not handled

$tms_lib'HOME = "/ctms/ctms";

package tms_lib;
use Carp::Assert;

assert($HOME eq '/ctms/ctms');
print "$0 - test passed!\n";
