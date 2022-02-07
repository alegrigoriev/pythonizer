# issue 56 - Array assignments to a list of scalars raise exceptions on mismatches

use Carp::Assert;

# Array assignments to a list of scalars raise exceptions on mismatches. 
# In perl they silently copy over as many elements as they can and fill 
# in the rest with undef if need be. Mimic this behavior in the generated code. 
# For example:
#

my @arr = ('a', 'b', 'c');
($thing1, $thing2) = @arr;   # copy over the first 2 things
assert($thing1 eq 'a' && $thing2 eq 'b');
($t1, $t2, $t3, $t4) = @arr;   # copy over the 3 elements - $t4 is undef
assert($t1 eq 'a' && $t2 eq 'b' && $t3 eq 'c' && !$t4);

print "$0 - test passed!\n";
