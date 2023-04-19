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

# Now for some chatGPT-4 generated tests:

#!/usr/bin/perl

use strict;
use warnings;

use Carp::Assert;

# Test 1: Basic autovivification
{
    my %hash;
    assert(!exists $hash{foo}{bar}, "foo and bar keys do not exist");

    $hash{foo}{bar} = "value";
    assert(exists $hash{foo}{bar}, "foo and bar keys exist after assignment");
    assert($hash{foo}{bar} eq "value", "foo => bar value is 'value'");
}

# Test 2: Autovivification with multiple levels
{
    my %hash;
    assert(!exists $hash{a}{b}{c}, "a, b and c keys do not exist");

    $hash{a}{b}{c} = "nested";
    assert(exists $hash{a}{b}{c}, "a, b and c keys exist after assignment");
    assert($hash{a}{b}{c} eq "nested", "a => b => c value is 'nested'");
}

# Test 3: Autovivification with arrays
{
    my %hash;
    assert(!exists $hash{array}[0], "array key with index 0 does not exist");

    $hash{array}[0] = "first";
    assert(exists $hash{array}[0], "array key with index 0 exists after assignment");
    assert($hash{array}[0] eq "first", "array => [0] value is 'first'");
}

# Test 4: Autovivification with mixed structures
{
    my %hash;
    assert(!exists $hash{mixed}[0]{key}, "mixed key with index 0 and key do not exist");

    $hash{mixed}[0]{key} = "mixed_value";
    assert(exists $hash{mixed}[0]{key}, "mixed key with index 0 and key exist after assignment");
    assert($hash{mixed}[0]{key} eq "mixed_value", "mixed => [0] => key value is 'mixed_value'");
}

# Test 5: No autovivification when using 'no autovivification'
{
	#no autovivification;

    my %hash;
	#eval { $hash{noauto}{key} };
	#assert(!exists $hash{noauto}{key}, "noauto and key do not exist (no autovivification)");

	#use autovivification;
    $hash{noauto}{key} = "noauto_value";
    assert(exists $hash{noauto}{key}, "noauto and key exist after assignment");
    assert($hash{noauto}{key} eq "noauto_value", "noauto => key value is 'noauto_value'");
}

# Test 6: Initialized hashref containing an arrayref
{
    my $hashref = {
        key => [ 'zero', 'one', 'two' ],
    };

    assert($hashref->{key}->[0] eq 'zero', "hashref key => [0] value is 'zero'");
    assert($hashref->{key}->[1] eq 'one', "hashref key => [1] value is 'one'");
    assert($hashref->{key}->[2] eq 'two', "hashref key => [2] value is 'two'");
}

# Test 7: Adding elements to the arrayref by index
{
    my $hashref = {
        key => [ 'zero', 'one', 'two' ],
    };

    $hashref->{key}->[3] = 'three';
    $hashref->{key}->[4] = 'four';

    assert($hashref->{key}->[3] eq 'three', "hashref key => [3] value is 'three'");
    assert($hashref->{key}->[4] eq 'four', "hashref key => [4] value is 'four'");
}

# Test 8: Autovivification with nested arrayrefs
{
    my $hashref = {
        key => [ 'zero', 'one', 'two' ],
    };
    assert(!exists $hashref->{nested}[0][0], "nested key with index 0 and nested index 0 do not exist");

    $hashref->{nested}[0][0] = 'nested_zero';
    assert(exists $hashref->{nested}[0][0], "nested key with index 0 and nested index 0 exist after assignment");
    assert($hashref->{nested}[0][0] eq 'nested_zero', "nested => [0] => [0] value is 'nested_zero'");
}

# Test 9: Autovivification with arrayref and hashref mixed
{
    my $hashref = {
        key => [ 'zero', 'one', 'two' ],
    };
    assert(!exists $hashref->{mixed_array}[0]{nested_key}, "mixed_array key with index 0 and nested_key do not exist");

    $hashref->{mixed_array}[0]{nested_key} = 'mixed_nested';
    assert(exists $hashref->{mixed_array}[0]{nested_key}, "mixed_array key with index 0 and nested_key exist after assignment");
    assert($hashref->{mixed_array}[0]{nested_key} eq 'mixed_nested', "mixed_array => [0] => nested_key value is 'mixed_nested'");
}

# Test 10: No autovivification with arrayrefs using 'no autovivification'
{
	#no autovivification;

    my $hashref = {
        key => [ 'zero', 'one', 'two' ],
    };
	#eval { $hashref->{noauto_array}[0][0] };
	#assert(!exists $hashref->{noauto_array}[0][0], "noauto_array key with index 0 and nested index 0 do not exist (no autovivification)");

	#use autovivification;
    $hashref->{noauto_array}[0][0] = 'noauto_nested_zero';
    assert(exists $hashref->{noauto_array}[0][0], "noauto_array key with index 0 and nested index 0 exist after assignment");
    assert($hashref->{noauto_array}[0][0] eq 'noauto_nested_zero', "noauto_array => [0] => [0] value is 'noauto_nested_zero'");
}

# Test 11: Arrayref containing an initialized hashref
{
    my $arrayref = [
        { key1 => 'value1', key2 => 'value2' },
    ];

    assert($arrayref->[0]{key1} eq 'value1', "arrayref => [0] => key1 value is 'value1'");
    assert($arrayref->[0]{key2} eq 'value2', "arrayref => [0] => key2 value is 'value2'");
}

# Test 12: Adding elements to the initialized hashref inside arrayref
{
    my $arrayref = [
        { key1 => 'value1', key2 => 'value2' },
    ];

    $arrayref->[0]{key3} = 'value3';
    assert($arrayref->[0]{key3} eq 'value3', "arrayref => [0] => key3 value is 'value3'");
}

# Test 13: Autovivification with nested hashrefs inside arrayref
{
    my $arrayref = [
        { key1 => 'value1', key2 => 'value2' },
    ];
    assert(!exists $arrayref->[0]{nested}{key}, "arrayref index 0 and nested key do not exist");

    $arrayref->[0]{nested}{key} = 'nested_value';
    assert(exists $arrayref->[0]{nested}{key}, "arrayref index 0 and nested key exist after assignment");
    assert($arrayref->[0]{nested}{key} eq 'nested_value', "arrayref => [0] => nested => key value is 'nested_value'");
}

# Test 14: Autovivification with arrayref inside hashref inside arrayref
{
    my $arrayref = [
        { key1 => 'value1', key2 => 'value2' },
    ];
    assert(!exists $arrayref->[0]{nested_array}[0], "arrayref index 0, nested_array and index 0 do not exist");

    $arrayref->[0]{nested_array}[0] = 'nested_array_value';
    assert(exists $arrayref->[0]{nested_array}[0], "arrayref index 0, nested_array and index 0 exist after assignment");
    assert($arrayref->[0]{nested_array}[0] eq 'nested_array_value', "arrayref => [0] => nested_array => [0] value is 'nested_array_value'");
}

# Test 15: No autovivification with hashrefs inside arrayref using 'no autovivification'
{
    #no autovivification;

    my $arrayref = [
        { key1 => 'value1', key2 => 'value2' },
    ];
    #eval { $arrayref->[0]{noauto_nested}{key} };
    #assert(!exists $arrayref->[0]{noauto_nested}{key}, "arrayref index 0, noauto_nested and key do not exist (no autovivification)");

    #use autovivification;
    $arrayref->[0]{noauto_nested}{key} = 'noauto_nested_value';
    assert(exists $arrayref->[0]{noauto_nested}{key}, "arrayref index 0, noauto_nested and key exist after assignment");
    assert($arrayref->[0]{noauto_nested}{key} eq 'noauto_nested_value', "arrayref => [0] => noauto_nested => key value is 'noauto_nested_value'");
}

print "$0 - test passed!\n";
