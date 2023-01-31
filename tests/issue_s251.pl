# issue s251 - Implement smartmatch (~~) operator
require  v5.28.0;
no warnings 'experimental';

use Carp::Assert;

# Test against undefined
my $undef;
assert( $undef ~~ undef, "Check whether undefined" );

# Test against object
my $num = 10;
my $obj = SomeClass->new($num);
assert( $obj ~~ $num, "Invoke ~~ overloading on Object, or fall back to numeric equality" );
my $objo = OtherClass->make($num);
assert( $objo ~~ $num, "Fall back to numeric equality on Object" );

# Test against array
my @array1 = (1, 2, 3);
my @array2 = (4, 5, 6);
assert( !(@array1 ~~ @array2), "Arrays have different elements" );

my @array3 = (1, 2, 3);
my @array4 = (1, 2, 3);
assert( @array3 ~~ @array4, "Arrays have the same elements" );

# Test against hash
my %hash1 = (a => 1, b => 2, c => 3);
my @array5 = (a, b, d);
assert(@array5 ~~ %hash1, "Any array elements exist as hash keys");

# Test against code
sub is_even {
    my $num = shift;
    return $num % 2 == 0;
}

my @array6 = (1, 2, 3, 4, 5);
assert( !(@array6 ~~ \&is_even), "All array elements are not even" );

my @array7 = (2, 4, 6);
assert( @array7 ~~ \&is_even, "All array elements are even" );

# Test against regex
my $regex = qr/[a-z]/;
my @array8 = (a, b, c);
assert(@array8 ~~ $regex, "All array elements match regex");

# Test simple array contains
assert('a' ~~ @array8, "Array contains match a");
assert('b' ~~ @array8, "Array contains match b");
assert('c' ~~ @array8, "Array contains match c");
assert(!('d' ~~ @array8), "Array not contains match d");

# Test simple hash key contains
assert('a' ~~ %hash1, "Hash key contains match a");
assert('b' ~~ %hash1, "Hash key contains match b");
assert('c' ~~ %hash1, "Hash key contains match c");
assert(!('d' ~~ %hash1), "Hash key not contains match d");

sub test_smart_match {
    my $undef;
    my $num = 10;
    my $nummy = "10";
    my @array1 = (1, 2, 3);
    my @array2 = (4, 5, 6);
    my @array3 = (4,5,6);
    my %hash1 = (a => 1, b => 2, c => 3);
    my %hash2 = (d => 4, e => 5, f => 6);
    my $regex = qr/^\d+$/;
    my $code = sub {return 1 if $_[0] =~ /^\d+$/};
    my $obj = SomeClass->new(10);
    my $obj10 = SomeClass->new(10);
    my $obj11 = SomeClass->new(11);

    # Test against undef
    assert($undef ~~ undef, "Check whether undefined");

    # Test against object
    assert( $obj ~~ $obj10, "Invoke ~~ overloading on Object" );
    assert( !($obj ~~ $obj11), "Invoke ~~ overloading on different Object" );

    # Test against array
    assert( !(@array1 ~~ @array2), "Recurse on paired elements of non-matching arrays" );
    assert( !(@array1 ~~ ['x', 'y']), "Recurse on paired elements of non-matching arrays with constant arrayref" );
    assert( @array2~~@array3, "Recurse on paired elements of matching arrays" );
    assert( ('x', 'y')~~('x', 'y'), "Recurse on paired elements of matching constant arrays" );
    assert( [['x1', 'x2'], 'y']~~[['x1', 'x2'], 'y'], "Recurse on paired elements of matching arrayref" );
    #assert( @array1 ~~ grep { exists $hash1{$_} } @array1, "Any array elements exist as hash keys" );
    assert( @array1 ~~ $regex, "Any array elements pattern match regex" );
    assert( !(@array1 ~~ undef), "Undef not in array" );
    @arrayu = (@array1, undef);
    assert( $undef ~~ @arrayu, "Undef in array" );
    #assert( @array1 ~~ grep { $undef ~~ $_ } @array1, "Smartmatch each array element" );

    # Test against hash
    #assert( (keys %hash1) ~~ %hash1, "All same keys in both hashes" );
    my @hash1keys = ('a', 'b', 'c');
    assert( @hash1keys ~~ %hash1, "Any array elements exist as hash keys" );
    assert( /[a-c]/ ~~ %hash1, "Any hash keys pattern match regex" );
    assert( /[A-C]/i ~~ %hash1, "Any hash keys pattern match regex ignore case" );
    assert( !(/[A-C]/ ~~ %hash1), "Any hash keys pattern doesn't match regex" );
    assert( !($undef ~~ %hash1), "Always false (undef cannot be a key)" );
    assert( 'a' ~~ %hash1, "Hash key existence" );
    assert( !('A' ~~ %hash1), "Hash key non-existence" );

     # Test against code
    assert( @array1 ~~ sub {return 1 if $_[0] =~ /^\d+$/}, "Sub returns true on all array elements" );
    assert( %hash1 ~~ sub {return 1 if $_[0] =~ /^\w$/}, "Sub returns true on all hash keys" );
    assert( $num ~~ sub {return 1 if $_[0] =~ /^\d+$/}, "Sub passed Any returns true" );

    # Test against regex
    assert( @array1 ~~ $regex, "Any array elements match regex" );
    assert( %hash1 ~~ /a/, "Any hash keys match regex" );
    assert( %hash1 ~~ /A/i, "Any hash keys match regex ignore case" );
    assert( !(%hash1 ~~ /A/), "Any hash keys doesn't match regex" );
    assert( $num ~~ $regex, "Pattern match" );

    # Other test cases
    assert( $obj ~~ $num, "Invoke ~~ overloading on Object, or fall back to numeric equality" );
    assert( !($obj ~~ 11), "Doesn't match - Invoke ~~ overloading on Object, or fall back to numeric equality" );
    assert( $num ~~ $nummy, "Numeric equality vs string" );
    assert( !($undef ~~ $num), "Check whether undefined" );
    assert( $num ~~ $num, "Numeric equality" );
    assert( !(11 ~~ $num), "Numeric non-equality" );
    assert( 'abc' ~~ 'abc', "String equality");
    assert( !('abc' ~~ 'ABC'), "String non-equality");
}

package SomeClass;

sub new {
    my $class = shift;
    my $self = { val => shift };
    bless $self, $class;
    return $self;
}

use overload '~~' => \&match;
#use Data::Dumper;

sub match {
    #print Dumper(\@_);
    my ($self, $other, $swap) = @_;
    #print "match($self->{val} vs $other, $swap)\n";
    if(ref $other) {
      return $self->{val} == $other->{val};
    }
    return $self->{val} == $other;
}

package OtherClass;

sub make {
    my $class = shift;
    my $self = { val => shift };
    bless $self, $class;
    return $self;
}

use overload '==' => \&num_eq, fallback=>1;

sub num_eq {
    my ($self, $other, $swap) = @_;
    if(ref $other) {
      return $self->{val} == $other->{val};
    }
    return $self->{val} == $other;
}

main::test_smart_match();

print "$0 - test passed!\n";

