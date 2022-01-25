# If the perl variables happen to match python keywords, they should be escaped using a trailing '_'. Here are the ones that need to be escaped: False None True and as assert async await break class continue def del elif else except finally for from global if import in is lambda nonlocal not or pass raise try while with yield.
use Carp::Assert;
sub False { 0; }
assert(!False);
sub True { 1; }
assert(True);
sub None { undef; }
assert(!defined None);
$and = "and";
assert($and eq 'and');
sub as { "as"; }
assert(as eq 'as');
@assert = ("assert");
assert($assert[0] eq 'assert');
$async = True;
assert($async);
sub await { "await"; }
assert(await eq 'await');
$break = 'break';
assert($break eq 'break');
sub class { "class"; }
assert(class eq 'class');
%continue = (con=>'tinue');
assert($continue{con} eq 'tinue');
sub def { "def"; }
assert(def eq 'def');
sub del { 1; }
assert(del);
($elif, $else, $except, $finally, $for) = (4,5,6,7,8);
assert($elif + $else + $except + $finally + $for == (4+5+6+7+8));
sub from { return "from"; }
assert(from eq "from");
sub global { 42; }
assert(global == 42);
($if, $import, $in, $is, $lambda, $nonlocal, $not, $or, $pass) = qw/if import in is lambda nonlocal not or pass/;
assert($if eq 'if' && $import eq 'import' && $in eq 'in' && $is eq 'is' &&
	$lambda eq 'lambda' && $nonlocal eq 'nonlocal' && $not eq 'not' &&
	$or eq 'or' && $pass eq 'pass');
%raise = (raise=>True);
assert($raise{raise});
$return = 'return';
assert($return eq 'return');
sub try { "try"; }
assert(try eq 'try');
@while = ('w', 'h', 'i', 'l', 'e');
assert($while[4] eq 'e');
sub with { "with"; }
assert(with eq 'with');
$yield = 13;
assert($yield == 13);
print "$0 - passed!\n";
