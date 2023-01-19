# issue s244a - Use of struct generates code with syntax error - this test defines our own sub struct
#use Class::Struct;
use Carp::Assert;

sub struct
{
    my $package = shift;
    *{"$package\::new"} = sub { bless {}, shift };
    for my $key (keys %{$_[0]}) {
        my $val = %{$_[0]}{$key};
        if($val eq '$') {
            *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        if(scalar(@_)) {
                                            $self->{$key} = $_[0];
                                        }
                                        return $self->{$key};
                                    };
        }
    }
}

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
