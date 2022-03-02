# Test some regex functions and variables
use Carp::Assert;

$String = "Geeks For Geeks";
$String =~ /For/;
assert($-[0] == 6);
assert($+[0] == 9);

@positions = ();
while($String =~ m/G/g) 
{
    #pos($String) = pos($string);
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

# Try some with the default variable
$_ = "The gray goose";
while(/(g.)/g) {
    $r .= $1;
}
assert($r eq 'grgo');
s/g/h/g;
assert($_ eq 'The hray hoose');

# Don't even think about it!  $x = "Cats are great.";
# Don't even think about it!  $y = $x =~ s/Cats/Dogs/r =~ s/Dogs/Frogs/r =~
# Don't even think about it!      s/Frogs/Hedgehogs/r;
# Don't even think about it!  assert($y eq "Hedgehogs are great.");

$x = "Bill the cat";
$x =~ s/(.)/$chars{$1}++;$1/eg; # final $1 replaces char with itself
push @freqs, "frequency of '$_' is $chars{$_}\n"
    foreach (sort {$chars{$b} <=> $chars{$a}} keys %chars);
assert(scalar(@freqs) == 9);
assert($freqs[0] =~ /frequency of '[\stl]' is 2/);
assert($freqs[-1] =~ /frequency of '[cBaihe]' is 1/);

# A case from our bootstrap:

sub pre_assign
{
	my $use_default_match = 0;
	my $j = 1;
	$ValClass[0] = 'q';
	$ValClass[$j] = 0;	# Mix the types
	$DEFAULT_MATCH = '_m';
	$ValPy[$j] = 0;
	$ValPy[0] = "$DEFAULT_MATCH:=42";
	for(my $i = 0; $i <= 1; $i++) {
	    if($ValClass[$i] eq 'q' && ($ValPy[$i] =~ /$DEFAULT_MATCH:=/)) {
	          $use_default_match = 1;
		  last;
	    }
        }
	assert($use_default_match == 1);
}
pre_assign();

# TDD: Set global and local vars from e-flag expr

$x =~ s/cat/$cnt++; 'dog'/e;
assert($x eq 'Bill the dog');
assert($cnt == 1);

sub mysub {
	my $frog = shift;
	my $counter;

	$x =~ s/dog/$c++; $frog/e;
	assert($x eq "Bill the $frog");
	assert($c == 1);

	$x =~ s/$frog/$counter++; 'cat'/e;
	assert($x eq 'Bill the cat');
	assert($counter == 1);

}
mysub('frog');

# Test an issue from bootstrapping:

sub rsv
{
    $v = shift;
    return $v . 'a';
}

$i = 0;
$ValPy[$i] = '{x}';
$ValPy[$i] =~ s/\{\w+\}/rsv($&)/e;
assert($ValPy[$i] eq '{x}a');
                       
print "$0 - test passed!\n";

