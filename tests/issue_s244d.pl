# issue s244d - Use of struct generates code with syntax error - this test defines a package outside of the struct call
use Carp::Assert;
#use lib '.';
package Car;
use Class::Struct;

struct (
    make => '$',
    model => '$',
    year => '$',
    features => '%',
    previous_owners => '@',
    address => 'Address',
);

package main;

# Test creating a new car object with valid attributes
my $car = Car->new(make => 'Toyota', model => 'Camry', year => '2022', features => {'color' => 'red', 'sunroof' => 1}, previous_owners => ['John', 'Mary', 'Bob']);
$car->address(Address->new("123 Main St", "Anytown", "CA", "12345"));
assert(defined $car, "Error creating car object");
assert($car->make eq 'Toyota', "Make is not correct");
assert($car->model eq 'Camry', "Model is not correct");
assert($car->year eq '2022', "Year is not correct");
assert(exists $car->features->{'color'} && $car->features->{'color'} eq 'red', "Color feature is not correct");
assert(exists $car->features->{'sunroof'} && $car->features->{'sunroof'} == 1, "Sunroof feature is not correct");
assert(scalar @{$car->previous_owners} == 3, "Number of previous owners is not correct");
assert(join(',', @{$car->previous_owners}) eq 'John,Mary,Bob', "Previous Owners are not correct");
assert($car->address->{street} eq "123 Main St", "The street should be '123 Main St'");
assert($car->address->{city} eq "Anytown", "The city should be 'Anytown'");
assert($car->address->{state} eq "CA", "The state should be 'CA'");
assert($car->address->{zip} eq "12345", "The zip should be '12345'");

# Define a class called "Address"
{
    package Address;

    sub new {
        my $class = shift;
        my $self = {
            street => shift,
            city => shift,
            state => shift,
            zip => shift,
        };
        bless $self, $class;
        return $self;
    }
}

print "$0 - test passed!\n";
