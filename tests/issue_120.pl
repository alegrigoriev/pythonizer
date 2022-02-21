# The m flag on regex gets treated as the start of a new regex

use Carp::Assert;

$expr = "line1\nline2\nline3\n";
my @lines = split(/^/m, $expr);

assert(@lines == 3 && join('', @lines) eq $expr);

print "$0 - test passed!\n";
