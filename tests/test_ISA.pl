use strict;
use warnings;

# Define My::BaseClass
package My::BaseClass;
sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{attribute} = 'value';
    return $self;
}
sub foo { 'foo' }
sub attribute { shift->{attribute} }

# Define My::Mixin
package My::Mixin;
sub bar { 'bar' }

# Test 1: Check that use parent correctly updates @ISA
{
    package My::Class1;
    #use parent -norequire => 'My::BaseClass';
    our @ISA = qw/My::BaseClass/;
    use Carp::Assert;
    assert(My::Class1->isa('My::BaseClass'));
}

# Test 2: Check that use parent correctly handles multiple parent classes
{
    package My::Class2;
    #use parent -norequire => qw( My::BaseClass My::Mixin );
    our @ISA = qw/My::BaseClass My::Mixin/;
    use Carp::Assert;
    assert(My::Class2->isa('My::BaseClass'));
    assert(My::Class2->isa('My::Mixin'));
}

# Test 3: Check that use parent correctly handles inheritance hierarchy
{
    package My::Class3;
    #use parent -norequire => 'My::BaseClass';
    our @ISA = ('My::BaseClass');
    package My::Subclass3;
    #use parent -norequire => 'My::Class';
    our @ISA = ('My::Class3');
    use Carp::Assert;
    assert(My::Subclass3->isa('My::Class3'));
    assert(My::Subclass3->isa('My::BaseClass'));
}

# Test 4: Check that use parent correctly handles multiple inheritance
{
    package My::Class4;
    #use parent -norequire => qw( My::BaseClass My::Mixin );
    our @ISA = qw/My::BaseClass My::Mixin/;
    package My::Subclass4;
    #use parent -norequire => 'My::Class';
    our @ISA = ('My::Class4');
    use Carp::Assert;
    assert(My::Subclass4->isa('My::Class4'));
    assert(My::Subclass4->isa('My::BaseClass'));
    assert(My::Subclass4->isa('My::Mixin'));
}

# Test 5: Check that use parent correctly handles inheritance of methods
{
    package My::Class5;
    #use parent -norequire => 'My::BaseClass';
    our @ISA = ('My::BaseClass');
    package My::Subclass5;
    #use parent -norequire => 'My::Class';
    our @ISA = ('My::Class5');
    my $obj = My::Subclass5->new;
    use Carp::Assert;
    assert($obj->foo eq 'foo', 'Inherited method correctly');
}

# Test 6: Check that use parent correctly handles inheritance of attributes
{
    package My::Class6;
    #use parent -norequire => 'My::BaseClass';
    our @ISA = ('My::BaseClass');
    package My::Subclass6;
    #use parent -norequire => 'My::Class';
    our @ISA = ('My::Class6');
    my $obj = My::Subclass6->new;
    use Carp::Assert;
    assert($obj->attribute eq 'value', 'Inherited attribute correctly');
}

print "$0 - test passed\n";
