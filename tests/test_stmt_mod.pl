# test statement modifiers

use Carp::Assert;

my $cnt = 0;

$cnt++ if $cnt == 0;
assert($cnt == 1);
$cnt++ unless $cnt == 0;
assert($cnt == 2);
$cnt++ while $cnt < 10;
assert($cnt == 10);
$cnt++ until $cnt >= 20;
assert($cnt == 20);
$cnt++ for 1, 2, 3, 4, 5;
assert($cnt == 25);
$cnt+=$_ foreach 1, 2, 3, 4, 5;
assert($cnt == 40);
my @arr = (1,2,3,4,5);
$cnt+=$_ foreach @arr;
assert($cnt == 55);

#
# from the documentation:
#

push @result, "Hello $_!" for qw(world Dolly nurse);
assert(join(' ', @result) eq 'Hello world! Hello Dolly! Hello nurse!');

push @eyes, $i++ while $i <= 10;
assert(join('', @eyes) eq '012345678910');

push @jays, $j++ until $j >  10;
assert(join('', @jays) eq '012345678910');

$_ = "My cat is better than your cat!";
push @cats, "Found cat at ${\(pos)}" while /cat/g;
assert(join(', ', @cats) eq 'Found cat at 6, Found cat at 30');


print "$0 - test passed!\n";
