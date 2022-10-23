# issue s125 - \xH doesn't generate proper python code
use Carp::Assert;

assert("\x1" eq chr 1);
assert("\xf" eq chr 15);
assert("\xF" eq chr 15);
assert("\x20" eq chr 32);
assert("\x{20}" eq chr 32);
assert("\x{2}" eq chr 2);
assert("\x1x" eq "\x01x");
assert("\\x1" eq '\\x1');	# not a hex escape
assert("\\\x1" eq "\\\x01");	# is a hex escape

print "$0 - test passed\n";
