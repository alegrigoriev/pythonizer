# issue s262 - map that updates a variable in the function generates incorrect code
use Carp::Assert;
no warnings 'experimental';

my @keys = ('k1', 'k2', 'k3');

my $cnt = 0;
my %ndx_map = map {$_ => $cnt++} @keys;

assert(%ndx_map ~~ {k1=>0, k2=>1, k3=>2});

sub create_map {
    my $keys = shift;
    my $start = shift;

    my %result = map {$_ => $$start++} @$keys;

    return \%result;
}

my $start = 4;
my $new_map = create_map(\@keys, \$start);
assert($new_map ~~ {k1=>4, k2=>5, k3=>6});
assert($start == 7);

# More cases from chatGPT:

my @list = (1..10);

# Test case: filter even numbers using grep using a simple expression
assert([grep { $_ % 2 == 0 } @list] ~~ [2, 4, 6, 8, 10]);

# Test case: filter even numbers using grep
assert([grep { my $x = $_; $x % 2 == 0; } @list] ~~ [2, 4, 6, 8, 10]);

# Test case: filter odd numbers using grep
assert([grep { my $x = $_; $x % 2 == 1; } @list] ~~ [1, 3, 5, 7, 9]);

# Test case: filter numbers greater than 5 using grep
assert([grep { my $x = $_; $x > 5; } @list] ~~ [6, 7, 8, 9, 10]);

@list = (1..5);

# Test case: square all the elements in the list using map, using a simple expression
assert([map { $_ * $_ } @list] ~~ [1, 4, 9, 16, 25]);

# Test case: square all the elements in the list using map
assert([map { my $x = $_; $x * $x; } @list] ~~ [1, 4, 9, 16, 25]);

# Test case: multiply all the elements in the list by 2 using map
assert([map { my $x = $_; $x * 2; } @list] ~~ [2, 4, 6, 8, 10]);

# Test case: concatenate a string to each element in the list using map
assert([map { my $x = $_; $x . "hello"; } @list] ~~ ["1hello", "2hello", "3hello", "4hello", "5hello"]);

print "$0 - test passed!\n";
