# Perl ? : operator generates bad code
use Carp::Assert;

%options = ();

$options{debug} = 0;
$redirect = $options{debug} ? "2>&1" : "2>&1 >/dev/null";
assert($redirect eq "2>&1 >/dev/null");

$options{debug} = 1;
$redirect = ($options{debug}) ? "2>&1" : "2>&1 >/dev/null";
assert($redirect eq "2>&1");

# Some more complicated cases (Not yet implemented)

assert($options{debug} ? "2>&1" : "2>&1 >/dev/null" eq "2>&1");
assert(($options{debug}) ? "2>&1" : "2>&1 >/dev/null" eq "2>&1");
assert(($options{debug} ? "2>&1" : "2>&1 >/dev/null") eq "2>&1");
assert((($options{debug}) ? "2>&1" : "2>&1 >/dev/null") eq "2>&1");

print "$0 - Test passed!\n";
