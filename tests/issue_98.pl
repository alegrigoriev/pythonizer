# issue 98 - Don't assume a subscript for bare words if space before the [...] in a string
use Carp::Assert;

$prog="issue_98";
assert("Usage: $prog [options] <file>" eq "Usage: issue_98 [options] <file>");
%hash=(options=>'this');
assert("Usage: $hash{options} <file>" eq "Usage: this <file>");

print "$0 - test passed!\n";
