# issue s152 - missing ';' on require should execute next line
use Carp::Assert;

# This is not a syntax error in that the '&' is being interpreted 
# as a bit-wise and, not as a sigil of a sub, so it's acting as
# require v5.24   &  CallSub();
#
# It seems that the "require v5.24" returns 1 and so does
# the sub, so the result of the expression is 1 & 1 = 1.
#
require v5.24
&CallSub();

sub CallSub {
    $called = 1;
}

assert($called);

$called = 0;
require v5.24 and CallSub();
assert($called);
$called = 0;
require v5.24 && CallSub();
assert($called);
require v5.24 or die "failed";
require test or die "no test!";
require "test.pm" or die "no test.pm!";

assert((3&CallSub()) == 1);
assert((0&CallSub()) == 0);
my $three = 3;
assert(($three&CallSub()) == 1);
assert(((3)&CallSub()) == 1);
assert(("$three"&CallSub()) == 1);

# Let's try some cases where the '&' is legitimately preceeded by a bareword or scalar

open(FILE, '>tmp.tmp') or die "Can't create tmp.tmp";

print FILE &CallSub;
print FILE "\n";
say FILE &CallSub;
my $i = 0;
$i++, say FILE &CallSub;
close(FILE);
open(my $fh, '>>tmp.tmp') or die "Can't open tmp.tmp for appending";
print $fh &CallSub;
print $fh "\n";
say $fh &CallSub;
close($fh);

assert($i == 1);

open(IN, "<tmp.tmp") or die "Can't open tmp.tmp";
$tot = 0;
while(<IN>) {
    chomp;
    assert(/^1$/);
    $tot++;
}
assert($tot == 5);

if(0) {
    $i++, warn "warning not produced";
}

print "$0 - test passed\n";
