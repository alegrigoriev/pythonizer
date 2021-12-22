# Test some regex functions and variables
use Carp::Assert;

$String = "Geeks For Geeks";
$String =~ /For/;
assert($-[0] == 6);
assert($+[0] == 9);

@positions = ();
while($String =~ m/G/g) {
    push @positions, pos($String);
}
assert(scalar(@positions) == 2 && $positions[0] == 1 && $positions[1] == 11);
$count = 0;
foreach my $m ($String =~ m/G/g) {
    $count++;
    assert($m eq 'G');
}
assert($count == 2);
$x = "cat dog house";
@positions = ();
@words = ();
while ($x =~ /(\w+)/g) {
    push @words, $1;
    push @positions, pos $x;
}
assert(join('', @words) eq 'catdoghouse');
assert(join(',', @positions) eq '3,7,13');
@words = ();
@words = ($x =~ /(\w+)/g);
assert(join('', @words) eq 'catdoghouse');

$x = "Time to feed the cat!";
$x =~ s/cat/hacker/;   # $x contains "Time to feed the hacker!"
assert($x eq "Time to feed the hacker!");
if ($x =~ s/^(Time.*hacker)!$/$1 now!/) {
    $more_insistent = 1;
}
assert($x eq 'Time to feed the hacker now!');
assert($more_insistent);

$y = "'quoted words'";
$y =~ s/^'(.*)'$/$1/;  # strip single quotes,
assert($y eq "quoted words");

$x = "I batted 4 for 4";
$x =~ s/4/four/;   # doesn't do it all:
assert($x eq "I batted four for 4");

$x = "I batted 4 for 4";
$x =~ s/4/four/g;  # does it all:
assert($x eq "I batted four for four");

$x = "I like dogs.";
$y = $x =~ s/dogs/cats/r;
assert($x eq 'I like dogs.');
assert($y eq 'I like cats.');

$x = "I like dogs.";
$y = $x =~ s/elephants/cougars/r;
assert($x eq 'I like dogs.');
assert($y eq 'I like dogs.');

$x = "Cats are great.";
$y = $x =~ s/Cats/Dogs/r =~ s/Dogs/Frogs/r =~
    s/Frogs/Hedgehogs/r, "\n";
assert($y eq "Hedgehogs are great.");

$x = "Bill the cat";
$x =~ s/(.)/$chars{$1}++;$1/eg; # final $1 replaces char with itself
push @freqs, "frequency of '$_' is $chars{$_}\n"
    foreach (sort {$chars{$b} <=> $chars{$a}} keys %chars);
assert(scalar(@freqs) == 9);
assert($freqs[0] =~ /frequency of '[\stl]' is 2/);
assert($freqs[-1] =~ /frequency of '[cBaihe]' is 1/);
                       
print "$0 - test passed!\n";

