# issue 89: 'q' used as hash key - actually anything perl recognizes
# causes a problem for pythonizer as a hash key
use Carp::Assert;

#%h = ();
$h{q} = 1;
assert($h{q} == 1);
$h{and} = 2;
assert($h{and} == 2);
$h{delete} = 3;
assert($h{delete} == 3);
$h{assert} = 4;
assert($h{assert} == 4);
$h{else} = 5;
assert($h{else} == 5);
$h{my} = 6;
assert($h{my} == 6);
$h{return} = 7;
assert($h{return} == 7);
$h{print} = 8;
assert($h{print} == 8);
$h{x} = 9;
assert($h{x} == 9);
$h{qq} = 10;
assert($h{qq} == 10);
$h{m} = 11;
assert($h{m} == 11);
$h{eq} = 12;
assert($h{eq} == 12);
$h{use} = 13;
assert($h{use} == 13);


assert($h{qq/q/} == 1);
assert($h{q/qq/} == 10);
delete $h{delete};
assert(!exists $h{delete});

my %i = (qw=>14, use=>15);
assert($i{qw} == 14 && $i{use} == 15);

print("$0 - test passed!\n");

