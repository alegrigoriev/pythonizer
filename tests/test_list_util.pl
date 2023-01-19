use Carp::Assert;
use List::Util qw(sum min max);

# Test sum function
assert sum(1, 2, 3) == 6, 'sum test 1 failed';
assert sum(-1, -2, 3) == 0, 'sum test 2 failed';
assert sum(0) == 0, 'sum test 3 failed';
# Try a couple w/o parens
my $total = sum 1, 2, 3;
assert($total == 6, 'sum test 4 failed');

$total = sum 1, '2', 3;
assert($total == 6, 'sum test 5 failed');

# Test min function
assert min(1, 2, 3) == 1, 'min test 1 failed';
assert min(-1, -2, 3) == -2, 'min test 2 failed';
assert min(0) == 0, 'min test 3 failed';

# Test max function
assert max(1, 2, 3) == 3, 'max test 1 failed';
assert max(-1, -2, 3) == 3, 'max test 2 failed';
assert max(0) == 0, 'max test 3 failed';

# Combo w/o parens
my $value = sum 1, 2, max 3, 2;
assert($value == 6, 'combo test failed');

assert((0 or max 2, 3), 'or with max test failed');

use List::Util qw(maxstr minstr product sum sum0);

# Test maxstr function
assert maxstr('foo', 'bar', 'baz') eq 'foo', 'maxstr test 1 failed';
assert maxstr(123, 'abc', 'def') eq 'def', 'maxstr test 2 failed';
assert maxstr(undef, 'abc', 'def') eq 'def', 'maxstr test 3 failed';

# Test minstr function
assert minstr('foo', 'bar', 'baz') eq 'bar', 'minstr test 1 failed';
assert minstr(123, 'abc', 'def') eq '123', 'minstr test 2 failed';
assert minstr(undef, 'abc', 'def') eq undef, 'minstr test 3 failed';

# Test product function
assert product(1, '2', 3) == 6, 'product test 1 failed';
assert product(-1, -2, -3) == -6, 'product test 2 failed';
assert product(0) == 0, 'product test 3 failed';

# Test sum function
assert sum(1, 2, 3) == 6, 'sum test 1 failed';
assert sum(-1, -2, 3) == 0, 'sum test 2 failed';
assert sum(0) == 0, 'sum test 3 failed';

# Test sum0 function
assert sum0(1, 2, 3) == 6, 'sum0 test 1 failed';
assert sum0(-1, -2, 3) == 0, 'sum0 test 2 failed';
assert sum0(0) == 0, 'sum0 test 3 failed';
my @empty = ();
assert sum0(@empty) == 0, 'sum0 test 3 failed';

# Tests using arrays instead of lists
my @numbers = (1, 2, 3, 4, 5);
my @strings = ('123', 'foo', 'bar', 'baz', 'qux');

# Test min function
assert min(@numbers) == 1, 'min test 1 failed';
assert min(reverse @numbers) == 1, 'min test 2 failed';

# Test minstr function
assert minstr(@strings) eq '123', 'minstr test 1 failed';
assert minstr(reverse @strings) eq '123', 'minstr test 2 failed';

# Test max function
assert max(@numbers) == 5, 'max test 1 failed';
assert max(reverse @numbers) == 5, 'max test 2 failed';

# Test maxstr function
assert maxstr(@strings) eq 'qux', 'maxstr test 1 failed';
assert maxstr(reverse @strings) eq 'qux', 'maxstr test 2 failed';

# Test product function
assert product(@numbers) == 120, 'product test 1 failed';
assert product(reverse @numbers) == 120, 'product test 2 failed';

# Test sum function
assert sum(@numbers) == 15, 'sum test 1 failed';
assert sum(reverse @numbers) == 15, 'sum test 2 failed';

# Test sum0 function
assert sum0(@numbers) == 15, 'sum0 test 1 failed';
assert sum0(reverse @numbers) == 15, 'sum0 test 2 failed';

sub mixed_type_test {
    # Tests using arrays instead of lists - this time have it be mixed type
    my @numbers = (1, 2, '3', 4, 5);
    my @strings = (123, 'foo', 'bar', 'baz', 'qux');

    # Test min function
    assert min(@numbers) == 1, 'min test 1 failed';
    assert min(reverse @numbers) == 1, 'min test 2 failed';

    # Test minstr function
    assert minstr(@strings) eq '123', 'minstr test 1 failed';
    assert minstr(reverse @strings) eq '123', 'minstr test 2 failed';

    # Test max function
    assert max(@numbers) == 5, 'max test 1 failed';
    assert max(reverse @numbers) == 5, 'max test 2 failed';

    # Test maxstr function
    assert maxstr(@strings) eq 'qux', 'maxstr test 1 failed';
    assert maxstr(reverse @strings) eq 'qux', 'maxstr test 2 failed';

    # Test product function
    assert product(@numbers) == 120, 'product test 1 failed';
    assert product(reverse @numbers) == 120, 'product test 2 failed';

    # Test sum function
    assert sum(@numbers) == 15, 'sum test 1 failed';
    assert sum(reverse @numbers) == 15, 'sum test 2 failed';

    # Test sum0 function
    assert sum0(@numbers) == 15, 'sum0 test 1 failed';
    assert sum0(reverse @numbers) == 15, 'sum0 test 2 failed';
}
mixed_type_test();

my $min_number = 1;
my $max_number = 5;
my $min_string = 'bar';
my $max_string = 'qux';

# Test min function
assert min($min_number, $max_number) == $min_number, 'min test 1 failed';
assert min($max_number, $min_number) == $min_number, 'min test 2 failed';

# Test minstr function
assert minstr($min_string, $max_string) eq $min_string, 'minstr test 1 failed';
assert minstr($max_string, $min_string) eq $min_string, 'minstr test 2 failed';

# Test max function
assert max($min_number, $max_number) == $max_number, 'max test 1 failed';
assert max($max_number, $min_number) == $max_number, 'max test 2 failed';

# Test maxstr function
assert maxstr($min_string, $max_string) eq $max_string, 'maxstr test 1 failed';
assert maxstr($max_string, $min_string) eq $max_string, 'maxstr test 2 failed';

# Test product function
assert product($min_number, $max_number) == 5, 'product test 1 failed';
assert product($max_number, $min_number) == 5, 'product test 2 failed';

# Test sum function
assert sum($min_number, $max_number) == 6, 'sum test 1 failed';
assert sum($max_number, $min_number) == 6, 'sum test 2 failed';

# Test sum0 function
assert sum0($min_number, $max_number) == 6, 'sum0 test 1 failed';
assert sum0($max_number, $min_number) == 6, 'sum0 test 2 failed';


print "$0 - test passed!\n";
