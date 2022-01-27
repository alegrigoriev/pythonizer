# issue_115: Chained initializers don't work properly unless you have TypeGlobs or Arrays

use Carp::Assert;

%peer = %ckt = %fac = ();
$peer{k} = 'v';
assert(scalar(%peer) == 1);
assert(scalar(%ckt) == 0);
assert(scalar(%fac) == 0);

%Peer = %Ckt = %Fac = ('yes', 'no');
assert(%Peer{yes} eq 'no');
assert(%Ckt{yes} eq 'no');
assert(%Fac{yes} eq 'no');
$Peer{k} = 'v';
assert(scalar(%Peer) == 2);
assert(scalar(%Ckt) == 1);
assert(scalar(%Fac) == 1);

#my (%PEER, %CKT, %FAC) = ('yes', 'no', 'baby', 'maybe');
##print "@{[%PEER]}, @{[%CKT]}, @{[%FAC]}\n";
#assert(%PEER{yes} eq 'no');
#assert(%PEER{baby} eq 'maybe');
#assert(!exists $CKT{yes});
#assert(!exists $FAC{yes});
#$PEER{k} = 'v';
#assert(scalar(%PEER) == 3);
#assert(scalar(%CKT) == 0);
#assert(scalar(%FAC) == 0);

@ar1 = @ar2 = @ar3 = ();
push @ar1, 'val';
assert(scalar(@ar1) == 1);
assert(scalar(@ar2) == 0);
assert(scalar(@ar3) == 0);

@ar4 = @ar5 = @ar6 = (1,2);
push @ar4, 3;
assert(scalar(@ar4) == 3);
assert(scalar(@ar5) == 2);
assert(scalar(@ar6) == 2);

#my (@ar7, @ar8, @ar9) = (7,8);
#print "@ar7, @ar8, @ar9\n";
#push @ar7, 9;
#assert(scalar(@ar7) == 3);
#assert(scalar(@ar8) == 0);
#assert(scalar(@ar9) == 0);

$v0 = $v1 = $v2 = 'value';

$v0 .= '0';
assert($v0 eq 'value0');
assert($v1 eq 'value');
assert($v2 eq 'value');

my ($v3, $v4, $v5) = 'vvv';
$v3 .= '0';
assert($v3 eq 'vvv0');
assert(!$v4);
assert(!$v5);

# Let's mix it up a little:

($k, $v) = %h1 = %h2 = @a1 = @a2 = ('key', 'value');
assert($k eq 'key');
assert($v eq 'value');
assert($h1{key} eq 'value');
assert($h2{key} eq 'value');
assert(join(' ', @a1) eq 'key value');
assert(join(' ', @a2) eq 'key value');

# and finally, some TypeGlobs

sub mysub { "mysub" }
*SUB1 = *SUB2 = \&mysub;

assert(SUB1() eq 'mysub');
assert(SUB2() eq 'mysub');

print "$0 - test passed!\n";
