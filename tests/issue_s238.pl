# issue s238 - use overload '<=>' and 'cmp' are not respected
package TestClass;

# Define a class for testing the overloaded operators
use Carp::Assert;

# Overload the '<=>' operator
use overload '<=>' => \&compare_numeric;

# Overload the 'cmp' operator
use overload 'cmp' => \&compare_string;

# Constructor for creating new TestClass objects
sub new {
    my ($class, $value) = @_;
    my $self = {
        value => $value
    };
    bless $self, $class;
    return $self;
}

# Method for comparing TestClass objects using the overloaded '<=>' operator
sub compare_numeric {
    my ($self, $other, $reversed) = @_;

    # If one of the operands is a TestClass object and the other is not,
    # compare the value of the TestClass object to the non-object operand
    if (ref($self) eq 'TestClass' && !ref($other)) {
        if ($self->{value} < $other) {
            return $reversed ? 1 : -1;
        } elsif ($self->{value} > $other) {
            return $reversed ? -1 : 1;
        } else {
            return 0;
        }
    }

    # Otherwise, assert that the operands are both TestClass objects
    assert(ref($self) eq 'TestClass' && ref($other) eq 'TestClass', 'Can only compare TestClass objects');

    # Compare the values of the TestClass objects and return the result
    if ($self->{value} < $other->{value}) {
        return -1;
    } elsif ($self->{value} > $other->{value}) {
        return 1;
    } else {
        return 0;
    }
}

# Method for comparing TestClass objects using the overloaded 'cmp' operator
sub compare_string {
    my ($self, $other, $reversed) = @_;

    # If one of the operands is a TestClass object and the other is not,
    # compare the value of the TestClass object to the non-object operand
    if (ref($self) eq 'TestClass' && !ref($other)) {
        if ($self->{value} lt $other) {
            return $reversed ? 1 : -1;
        } elsif ($self->{value} gt $other) {
            return $reversed ? -1 : 1;
        } else {
            return 0;
        }
    }

    # Otherwise, assert that the operands are both TestClass objects
    assert(ref($self) eq 'TestClass' && ref($other) eq 'TestClass', 'Can only compare TestClass objects');

    # Compare the values of the TestClass objects and return the result
    if ($self->{value} lt $other->{value}) {
        return -1;
    } elsif ($self->{value} gt $other->{value}) {
        return 1;
    } else {
        return 0;
    }
}

# End of TestClass definition

# Test the overloaded '<=>' and 'cmp' operators

# Create some TestClass objects
my $obj1 = TestClass->new(5);
my $obj2 = TestClass->new(10);
my $obj3 = TestClass->new(5);
my $obj4 = TestClass->new('abc');
my $obj5 = TestClass->new('def');
my $obj6 = TestClass->new('abc');

eval {  # Operation """": no method found, argument in overloaded package TestClass
    assert("$obj1" != 5);
    assert("$obj4" ne 'abc');
};

# Test the '<=>' operator
assert(($obj1 <=> $obj2) == -1, 'TestClass objects not being compared correctly with <=>');
assert(($obj2 <=> $obj1) == 1, 'TestClass objects not being compared correctly with <=>');
assert(($obj1 <=> $obj2) == -1, 'TestClass objects not being compared correctly with <=>');
assert(($obj1 <=> $obj3) == 0, 'TestClass objects not being compared correctly with <=>');

assert(($obj2 <=> 5) == 1, 'TestClass objects not being compared correctly with <=>');
assert(($obj1 <=> 10) == -1, 'TestClass objects not being compared correctly with <=>');
assert(($obj2 <=> 5) == 1, 'TestClass objects not being compared correctly with <=>');
assert(($obj1 <=> 5) == 0, 'TestClass objects not being compared correctly with <=>');

assert((5 <=> $obj2) == -1, 'TestClass objects not being compared correctly with <=>');
assert((10 <=> $obj1) == 1, 'TestClass objects not being compared correctly with <=>');
assert((5 <=> $obj2) == -1, 'TestClass objects not being compared correctly with <=>');
assert((5 <=> $obj3) == 0, 'TestClass objects not being compared correctly with <=>');

# Test the 'cmp' operator
assert(($obj4 cmp $obj5) == -1, 'TestClass objects not being compared correctly with cmp');
assert(($obj5 cmp $obj4) == 1, 'TestClass objects not being compared correctly with cmp');
assert(($obj4 cmp $obj6) == 0, 'TestClass objects not being compared correctly with cmp');

assert(($obj4 cmp 'def') == -1, 'TestClass objects not being compared correctly with cmp');
assert(($obj5 cmp 'abc') == 1, 'TestClass objects not being compared correctly with cmp');
assert(($obj4 cmp 'abc') == 0, 'TestClass objects not being compared correctly with cmp');

assert(('abc' cmp $obj5) == -1, 'TestClass objects not being compared correctly with cmp');
assert(('def' cmp $obj4) == 1, 'TestClass objects not being compared correctly with cmp');
assert(('abc' cmp $obj6) == 0, 'TestClass objects not being compared correctly with cmp');

# Make sure cmp still works with non-string input
my $i = 1;
my $j = 2;
assert(($i cmp $j) == -1, 'Int objects not being compared correctly with cmp');
assert(($i cmp $i) == 0, 'Int objects not being compared correctly with cmp');
assert(($i cmp '1') == 0, 'Int objects not being compared correctly with cmp');
assert(($j cmp $i) == 1, 'Int objects not being compared correctly with cmp');
assert((undef cmp $i) == -1, 'undef objects not being compared correctly with cmp');
assert((undef cmp undef) == 0, 'undef objects not being compared correctly with cmp');
assert((undef cmp '') == 0, 'undef objects not being compared correctly with cmp');
assert(('' cmp undef) == 0, 'undef objects not being compared correctly with cmp');
assert(($i cmp undef) == 1, 'undef objects not being compared correctly with cmp');

print "$0 - test passed!\n";
