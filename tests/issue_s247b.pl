# issue s247b - exec { $0 } @args; generates bad code
use strict;
use warnings;

exec ("echo $0 - test passed!") or print STDERR "couldn't exec echo: $!\n";
