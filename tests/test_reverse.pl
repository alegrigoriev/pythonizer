# Written by chatGPT
use Carp::Assert;
no warnings 'experimental';

# Test list context
my @list = (1, 2, 3);
my @reversed_list = reverse @list;
assert([3, 2, 1] ~~ @reversed_list, 'reverse in list context');

# Test scalar context
my $scalar = 'hello';
my $reversed_scalar = reverse $scalar;
assert('olleh' eq $reversed_scalar, 'reverse in scalar context');

# Test default variable
$_ = 'hello';
$_ = reverse;
assert('olleh' eq $_, 'reverse using default variable');

# Test reverse of empty list
my @empty_list;
my @reversed_empty_list = reverse @empty_list;
assert(@reversed_empty_list ~~ [], 'reverse of empty list');

# Test reverse of empty string
my $empty_string = '';
my $reversed_empty_string = reverse $empty_string;
assert($reversed_empty_string eq '', 'reverse of empty string');

# Test reverse of a string of length 1
my $string_of_length_1 = 'a';
my $reversed_string_of_length_1 = reverse $string_of_length_1;
assert($reversed_string_of_length_1 eq 'a', 'reverse of a string of length 1');

# Test reverse of a number
my $number = 1234;
my $reversed_number = reverse $number;
assert($reversed_number eq 4321, 'reverse of a number');

# Test reverse in list context on hash
my %hash = (a => 1, b => 2, c => 3);
my %rhash = (1 => 'a', 2 => 'b', 3 => 'c');
my %reversed_hash = reverse %hash;
assert(%reversed_hash ~~ %rhash, 'reverse of hash');

# Test reverse in scalar context on hash
my $hash_scalar = reverse %hash;
#print "$hash_scalar\n";
assert($hash_scalar ~~ ['1a2b3c', '1a3c2b', '2b3c1a', '2b1a3c', '3c1a2b', '3c2b1a'], 'reverse in scalar context on hash');

print "$0 - test passed!\n";
