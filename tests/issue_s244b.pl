# issue s244b - Use of struct generates code with syntax error - this test defines our own sub struct, add @ and %
use Carp::Assert;
#use Class::Struct;

sub struct
{
    my $package = shift;
    *{"$package\::new"} = sub { 
        my $self = bless {}, shift;
        my %args = @_;
        for (keys %args) {
            $self->{$_} = $args{$_}
        }
        return $self;
    };
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
        } elsif($val eq '@') {
            *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        if(scalar(@_)) {
                                            if(ref $_[0] eq 'ARRAY') {
                                                $self->{$key} = $_[0];
                                            } elsif(scalar(@_) == 1) {
                                                return $self->{$key}->[$_[0]];
                                            } else {
                                                $self->{$key}->[$_[0]] = $_[1];
                                                return $_[1];
                                            }
                                        }
                                        return $self->{$key};
                                    };
        } elsif($val eq '%') {
            *{"$package\::$key"} = sub {
                                        my $self = shift;
                                        if(scalar(@_)) {
                                            if(ref $_[0] eq 'HASH') {
                                                $self->{$key} = $_[0];
                                            } elsif(scalar(@_) == 1) {
                                                return $self->{$key}->{$_[0]};
                                            } else {
                                                $self->{$key}->{$_[0]} = $_[1];
                                                return $_[1];
                                            }
                                        }
                                        return $self->{$key};
                                    };
        }
    }
}

struct Car => {
    make => '$',
    model => '$',
    year => '$',
    features => '%',
    previous_owners => '@',
};

# Test creating a new car object with valid attributes
my $car = Car->new(make => 'Toyota', model => 'Camry', year => '2022', features => {'color' => 'red', 'sunroof' => 1}, previous_owners => ['John', 'Mary', 'Bob']);
assert(defined $car, "Error creating car object");
assert($car->make eq 'Toyota', "Make is not correct");
assert($car->model eq 'Camry', "Model is not correct");
assert($car->year eq '2022', "Year is not correct");
assert(exists $car->features->{'color'} && $car->features->{'color'} eq 'red', "Color feature is not correct");
assert(exists $car->features->{'sunroof'} && $car->features->{'sunroof'} == 1, "Sunroof feature is not correct");
assert(scalar @{$car->previous_owners} == 3, "Number of previous owners is not correct");
assert(join(',', @{$car->previous_owners}) eq 'John,Mary,Bob', "Previous Owners are not correct");

print "$0 - test passed!\n";
