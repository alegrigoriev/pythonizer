# Test autovivification of arrays and hashes
use Carp::Assert;
#use Data::Dumper;

$desc[0] = 'a';
$desc[4] = 'd';
assert(scalar(@desc) == 5);
assert($desc[0] eq 'a');
assert(!defined $desc[1]);
assert($desc[4] eq 'd');
$desc[5]{k} = 'k';
assert($desc[5]{k} eq 'k');
$desc[6][2] = 't';
assert($desc[6][2] eq 't');
assert(!defined $desc[6][0]);
assert(! $desc[7][0]);   # makes $desc[7] and tests $desc[7][0]
assert(defined $desc[7]);

$hash{key0}{key1} = 'v';
assert($hash{key0}{key1} eq 'v');
$hash{key1}[0] = 'z';
assert($hash{key1}[0] eq 'z');

assert((ref \@desc) eq 'ARRAY');
assert((ref \%hash) eq 'HASH');

my %cats;
delete $cats{Buster};
my $foo = $cats{Buster};
assert(!defined $foo);
assert(!exists $cats{Buster});
assert("@{[%cats]}" eq '');
$cats{Buster}++;
assert("@{[%cats]}" eq 'Buster 1');
# We aren't gonna support this! $cats{Buster}{count} = 9;
# We aren't gonna support this! assert($cats{Buster}{count} == 9);
#print(Dumper(\$bar). "\n");
assert(!defined $cats{Harry}{count});
$foo = $cats{Harry}{count};
assert(!defined $foo);
assert(defined $cats{Harry});
$cats{Felix}{count} = 10;
assert($cats{Felix}{count} == 10);
#print(Dumper(\%cats). "\n");
#print("@{[%cats]}\n");
my @values = (1, 2, 3);
$values[3] = 4;
assert(@values == 4 && join('', @values) eq '1234');
my @arr = (5,6);
push @values, @arr;
assert(@values == 6 && join('', @values) eq '123456');
push @values, 7;
assert(@values == 7 && join('', @values) eq '1234567');

my %h = (key=>'value');
assert(scalar(%h) == 1);
$h{new}{extra} = 42;
assert(scalar(%h) == 2);
assert($h{key} eq 'value' && $h{new}{extra} == 42);
%h2 = (h2k=>'h2v');
%h = (%h, %h2);
assert(scalar(%h) == 3);
assert($h{key} eq 'value' && $h{new}{extra} == 42 && $h{h2k} eq 'h2v');
#@a = ('a', 'apple', 'b', 'banana');
my $i = 0;
$a[$i++] = 'a'; $a[$i++] = 'apple';
$a[$i++] = 'b'; $a[$i++] = 'banana';
assert($i == 4);
%h = (%h, @a);
assert($h{key} eq 'value' && $h{new}{extra} == 42 && $h{h2k} eq 'h2v');
assert($h{a} eq 'apple' && $h{b} eq 'banana');
assert(scalar(%h) == 5);

# Make sure arrays don't lose their magic if we manipulate them
my @items = (5, 3, 8);
@items = sort @items;
assert(join('', @items) eq '358');
$items[3] = 9;
assert(join('', @items) eq '3589');
@items = reverse sort @items;
assert(join('', @items) eq '9853');
$items[4] = 1;
assert(join('', @items) eq '98531');
my $reverse_it = 0;
my @new_items = ($reverse_it ? reverse sort @items : sort @items);
assert(join('', @new_items) eq '13589');
$new_items[5] = 10;
assert(join('', @new_items) eq '1358910');

$item = shift @items;
assert($item == 9);
assert(join('', @items) eq '8531');
$items[4] = 0;
assert(join('', @items) eq '85310');
unshift @items, 9;
assert(join('', @items) eq '985310');
$items[6] = -1;
assert(join('', @items) eq '985310-1');

# Samples from class2q.pl:

$line = "a|b|c|d|e|f";
@line = split /\|/, $line;
$key = "$line[1]|$line[2]";
push @{$classmap{$key}}, "exp|$line[5]";

assert(scalar(@{$classmap{$key}}) == 1);
#assert(${$classmap{$key}}[0] eq "exp|$line[5]");

$r = 'r';
$policy = 'policy';
$key2 = "$r|$policy";
foreach $class (keys %{$policy2class{$key2}})
{
	$cnt++;
}
assert(!$cnt);

$class = 'class';
$classkey = "$r|$class";
foreach (@{$classmap{$classkey}})
{
    $cnt++;
}
assert(!$cnt);

$newhash{k1}{k2} = $newarr[13];
$n = $newhash{k1}{k2};
assert("$n" eq '');

$key = "a|b";
$interfaces{$key}{inpolicy} = $line[18];
$interfaces{$key}{outpolicy} = $line[19];
$interfaces{$key}{classes}{$class}{q} = $line[20];
$key = "b|c";
$interfaces{$key}{inpolicy} = 'abc';
$interfaces{$key}{outpolicy} = 'def';
$interfaces{$key}{classes}{$class}{q} = 'q';

foreach $key (sort %interfaces) {
	foreach $class (sort keys %{$interfaces{$key}{classes}}) {
		$answer .= $key . $interfaces{$key}{classes}{$class}{q};
	}
}
assert($answer eq 'a|bb|cq');

assert($newarr[14] == 0);
assert($newarr[15] < 7);
assert($newarr[16] > -7);
assert($newarr[17] == undef);
assert($newarr[18] lt 'a');
assert($newarr[19] == $newarr[20]);
assert($newhash{k1}{k3} == 0);
assert($newhash{k1}{k4} == undef);
assert($newhash{k1}{k5} == '');
assert($newhash{k1}{k6} == $newarr[27]);
$newhash{k1}{k7} = 'abc';

print "$0 - test passed!\n";
