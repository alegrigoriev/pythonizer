# issue s182: do statement with for(each) statement modifier generates bad code
use Carp::Assert;

@arr=(3,4);
do {$tot+=$_} foreach @arr;
assert($tot == 7);

do {$tot+=$_} for @arr;
assert($tot == 14);

do {$tot+=$_; $cnt++} for (5, 6, 7);
assert($tot == 32);
assert($cnt == 3);

use feature qw/switch/;
no warnings 'experimental';

# Try 'when':
given($tot) {
    do {$tot++} when 32;
}
assert($tot == 33);

use Switch;
switch($tot) {
    do {$tot++} case (33);
}
assert($tot == 34);

print "$0 - test passed!\n";
