# issue s312 - Use of uninitialized value $Pythonizer::ValClass[2] in string eq at ../../Pythonizer.pm line 4935
use Carp::Assert;

my $obj1 = { foo => 'bar' };
my $obj2 = { baz => 'qux' };
my $obj3 = { fizz => 'buzz' };

sub weaken {
    my $obj = shift;
    
    $obj{_weakened} = 1;
}

sub isweak {
    my $obj = shift;

    return (exists $obj{_weakened});
}

sub setup_handle {
    my $handles = [$obj1, $obj2, $obj3];
    weaken($_) for @$handles;
    assert(isweak($handles->[0]) && isweak($handles->[1]) && isweak($handles->[2]));
    #assert(!isweak($obj1) && !isweak($obj2) && !isweak($obj3));
}

setup_handle();

print "$0 - test passed!\n";
