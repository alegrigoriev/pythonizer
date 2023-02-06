# pragma pythonizer -s
# Test of Text::Parsewords
# written by chatGPT
use strict;
use warnings;
use Text::ParseWords;
use Carp::Assert;

# Test 1: Basic parsing of a string into words
my $input = "apple pear banana";
my @expected_output = qw(apple pear banana);
my @actual_output = parse_line('\s+', 0, $input);
assert(scalar @actual_output == scalar @expected_output, "Output size does not match expected");
for (my $i = 0; $i < scalar @expected_output; $i++) {
  assert($actual_output[$i] eq $expected_output[$i], "Output does not match expected");
}

# Test 2: Parsing with quotes
$input = 'apple "pear banana"';
@expected_output = ("apple", "pear banana");
@actual_output = parse_line('\s+', 0, $input);
assert(scalar @actual_output == scalar @expected_output, "Output size does not match expected");
for (my $i = 0; $i < scalar @expected_output; $i++) {
  assert($actual_output[$i] eq $expected_output[$i], "Output does not match expected");
}

# Test 3: Parsing with escaped quotes
$input = 'apple "pear \\"banana\\""';
@expected_output = ("apple", 'pear "banana"');
@actual_output = parse_line('\s+', 0, $input);
assert(scalar @actual_output == scalar @expected_output, "Output size does not match expected");
for (my $i = 0; $i < scalar @expected_output; $i++) {
  assert($actual_output[$i] eq $expected_output[$i], "Output does not match expected");
}

# Test 4: Parsing with quotes and escaped quotes
$input = 'apple "pear \\"banana\\" cherry"';
@expected_output = ("apple", 'pear "banana" cherry');
@actual_output = parse_line('\s+', 0, $input);
assert(scalar @actual_output == scalar @expected_output, "Output size does not match expected");
for (my $i = 0; $i < scalar @expected_output; $i++) {
  assert($actual_output[$i] eq $expected_output[$i], "Output does not match expected");
}

# Test 5: Parsing with multiple delimiters
$input = 'apple,pear,banana';
@expected_output = qw(apple pear banana);
@actual_output = parse_line(',', 0, $input);
assert(scalar @actual_output == scalar @expected_output, "Output size does not match expected");
for (my $i = 0; $i < scalar @expected_output; $i++) {
  assert($actual_output[$i] eq $expected_output[$i], "Output does not match expected");
}

# Test 6: Parsing with multiple delimiters and quotes
$input = 'apple,"pear,banana",cherry';
@expected_output = ("apple", "pear,banana", "cherry");
@actual_output = parse_line(',', 0, $input);
assert(scalar @actual_output == scalar @expected_output, "Output size does not match expected");
for (my $i = 0; $i < scalar @expected_output; $i++) {
  assert($actual_output[$i] eq $expected_output[$i], "Output does not match expected");
}

# Test 7: Parsing with non-zero second argument
$input = 'apple, "pear, banana", cherry';
@expected_output = ("apple", ' "pear, banana"', " cherry");
@actual_output = parse_line(',', 1, $input);
assert(scalar @actual_output == scalar @expected_output, "Output size does not match expected");
for (my $i = 0; $i < scalar @expected_output; $i++) {
  assert($actual_output[$i] eq $expected_output[$i], "Output does not match expected");
}

print "$0 - test passed!\n";
