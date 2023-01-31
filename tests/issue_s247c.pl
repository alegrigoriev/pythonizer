# issue s247 - exec { $0 } @args; generates bad code
# LIST without brackets
use strict;
use warnings;

my @args = ($0, "-", "test", "passed!");
exec ('echo', @args) or print STDERR "couldn't exec echo: $!\n";
