# issue s253 - given/when doesn't work on object with overloaded smart match operator (~~)
use Carp::Assert;
use feature 'switch';
no warnings 'experimental';

package MyOverloadedObject {
    use overload '~~' => \&matches;
    sub new {
        my $class = shift;
        my $self = {};
        return bless $self, $class;
    }
    sub matches {
        my $self = shift;
        my $other = shift;
        return 1 if $other eq 'some string';
        return 0;
    }
}

my $obj = MyOverloadedObject->new();
my $assertion_executed = 0;

# Test that the ~~ operator returns the expected value when used with the object
my $result = $obj ~~ 'some string';
assert($result == 1, "Unexpected result from ~~ operator when used with object: $result");

# Test that the ~~ operator returns the expected value when used with a string
my $result2 = 'some string' ~~ $obj;
assert($result2 == 1, "Unexpected result from ~~ operator when used with string: $result2");

# Test that the ~~ operator returns the expected value when negated
my $neg_result = !($obj ~~ 'some other string');
assert($neg_result == 1, "Unexpected result from negated ~~ operator: $neg_result");

given($obj) {
    when ('some string') {
        assert(++$assertion_executed, "The ~~ operator returned the expected value when used with the object");
    }
    when ('some other string') {
        assert(0, "The ~~ operator returned an unexpected value when used with the object");
    }
    default {
        assert(0, "No matching when statement when used with the object");
    }
}

given('some string') {
    when ($obj) {
        assert($assertion_executed++, "The ~~ operator returned the expected value when used with a string");
    }
    when ('some other string') {
        assert(0, "The ~~ operator returned an unexpected value when used with a string");
    }
    default {
        assert(0, "No matching when statement when used with a string");
    }
}

assert($assertion_executed == 2, "Assertion was not executed");

print "$0 - test passed!\n";
