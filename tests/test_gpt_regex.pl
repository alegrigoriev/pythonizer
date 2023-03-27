# Test case: complex Perl program
# Written by: ChatGPT
use Carp::Assert;

# Define a subroutine that takes a string and a regular expression as arguments
# The subroutine will use the regular expression to match the string, and will
# return a list of all the capturing groups from the match
sub extract_groups {
  my ($string, $regex) = @_;

  # Use the regular expression to match the string
  my @groups = $string =~ /$regex/;

  # Return the list of capturing groups
  return @groups;
}

# Define a string and a regular expression
my $string = 'The quick brown fox jumps over the lazy dog';
my $regex = '(\w+)\s+(\w+)\s+(\w+)';

# Try using separate variables:
my ($first, $second, $third) = $string =~ /$regex/;
assert($first eq 'The');
assert($second eq 'quick');
assert($third eq 'brown');

# Try with a constant regex:
my ($fi, $se, $th) = $string =~ m'(\w+)\s+(\w+)\s+(\w+)';
assert($fi eq 'The');
assert($se eq 'quick');
assert($th eq 'brown');

# Call the extract_groups subroutine and store the result in a variable
my @words = extract_groups($string, $regex);

# Print the result to the screen
#print(join(', ', @words));
# Expected output: The, quick, brown

assert(join(', ', @words) eq 'The, quick, brown');

# Try using a qr regex:
my $qr_regex = qr/(\w+)\s+(\w+)\s+(\w+)/;
my @qr_words = extract_groups($string, $qr_regex);
assert(join(', ', @qr_words) eq 'The, quick, brown');

# Try using the 'e' flag in an anonymous sub
my $text = "Hello, world!";
my $expected_result = "Hello, WORLD!";
my $regex = qr/world/i;

my $sub = sub {
  my ($match) = @_;
  $match =~ s/\w+/$& eq 'world' ? uc($&) : $&/ge;
  return $match;
};

my $result = $text =~ s/$regex/$sub->($&)/e;

assert($result == 1); # Make sure the substitution was successful
assert($text eq $expected_result); # Make sure the text was modified as expected

print "$0 - test passed!\n";
