# error test for use overload
# pragma pythonizer verbose
sub subr {}

use overload {'++' => \subr, '--' => \subr, '!' => \subr, '-X' => \subr};      # Not handled by pythonizer

# print "Should complain about overload ++, --, !, and -X not supported\n";
print "Should warn about overload ++, -- not supported\n";
print "Should complain about overload !, and -X not supported\n";
print "$0 - test passed!\n";
