# issue s244 - Use of struct generates code with syntax error
use strict;
use warnings;
use Class::Struct;
use Carp::Assert;

# Define a struct called "Person" with fields "name", "age", and "gender"
struct Person => {
    name   => '$',
    age    => '$',
    gender => '$',
};

# Create an instance of the struct
my $p = Person->new();

# Set values for the struct's fields
$p->name("John Doe");
$p->age(35);
$p->gender("male");

# Print the values of the struct's fields
#print "Name: " . $p->name . "\n";
#print "Age: " . $p->age . "\n";
#print "Gender: " . $p->gender . "\n";

# Add tests
assert($p->name eq "John Doe", "The name should be 'John Doe'");
assert($p->age == 35, "The age should be 35");
assert($p->gender eq "male", "The gender should be 'male'");
print "$0 - test passed!\n";
