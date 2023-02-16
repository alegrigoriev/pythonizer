# issue s287 - implement 'isa' operator
use feature 'isa';

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
    assert(!(My::Class1 isa 'My::BaseClass'));  # isa only works for objects, unlike UNIVERSAL::isa

    my $obj = new My::BaseClass;
    assert($obj isa 'My::BaseClass');
    assert($obj isa My::BaseClass);
    my $class = 'My::BaseClass';
    assert($obj isa $class);

    $obj = new My::Class1;
    assert($obj isa 'My::Class1');
    assert($obj isa My::Class1);
    assert($obj isa My::BaseClass);
    assert($obj isa 'My::BaseClass');
}

# Test 2: Check that use parent correctly handles multiple parent classes
{
    package My::Class2;
    #use parent -norequire => qw( My::BaseClass My::Mixin );
    our @ISA = qw/My::BaseClass My::Mixin/;
    use Carp::Assert;
    my $obj = new My::Class2;
    assert($obj isa 'My::BaseClass');
    assert($obj isa My::Mixin);
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
    my $obj = new My::Subclass3;
    assert($obj isa 'My::Class3');
    assert($obj isa 'My::BaseClass');
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
    my $obj = new My::Subclass4;
    assert($obj isa 'My::Class4');
    assert($obj isa 'My::BaseClass');
    assert($obj isa 'My::Mixin');
    assert($obj isa My::Mixin);
}

print "$0 - test passed\n";
