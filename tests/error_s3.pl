# error test for use overload
sub subr {}

use overload {'++' => \subr, '--' => \subr, '!' => \subr, '-X' => \subr};      # Not handled by pythonizer

print "Should complain about overload ++, --, !, and -X not supported\n";
print "$0 - test passed!\n";
