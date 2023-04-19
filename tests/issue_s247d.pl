# issue s247d - exec { $0 } @args; generates bad code
# PROGRAM that's not in {...}:

use strict;
use warnings;
my $script = $0; 
my $program = 'echo';
my @args = ($program, "$0 - test passed!");
exec @args or die "Couldn't exec $program: $!";
