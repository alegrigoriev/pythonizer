# issue s203a - $self->PACKAGE::subname(...) generates incorrect code
# This one has MYPACKAGE defined in a separate file
# pragma pythonizer -M
use lib '.';
use MYPACKAGE;

# Define a subclass of MYPACKAGE with a different implementation of subname
package MYPACKAGE::SUBCLASS;
use parent -norequire=>'MYPACKAGE';
use Carp::Assert;

sub subname {
    my ($self, $input) = @_;

    assert($input eq 'valid_input', 'Invalid input detected') if DEBUG;
    return 'different_output';
}

# Define a subclass of MYPACKAGE::SUBCLASS with a different implementation of subname
package MYPACKAGE::SUBCLASS::SUBSUB;
use parent -norequire=>'MYPACKAGE::SUBCLASS';
use Carp::Assert;

sub subname {
    my ($self, $input) = @_;

    assert($input eq 'valid_input', 'Invalid input detected') if DEBUG;
    return 'even different_output';
}

package main;
use Carp::Assert;

# Set the DEBUG flag to a true value to enable assertion checks
local *MYPACKAGE::DEBUG = sub { 1 };

# Create an object of the subclass
my $self = MYPACKAGE::SUBCLASS->new;

# Test that $self->subname() calls the implementation of subname in the subclass
my $result = $self->subname('valid_input');
if ($result eq 'different_output') {
    ;
} else {
    assert(0, "\$self->subname() does not call subclass implementation");
}

# Create an object of the sub-subclass
my $self = MYPACKAGE::SUBCLASS::SUBSUB->new;

# Test that $self->subname() calls the implementation of subname in the sub-subclass
my $result = $self->subname('valid_input');
if ($result eq 'even different_output') {
    ;
} else {
    assert(0, "\$self->subname() does not call sub-subclass implementation");
}

# Test that $self->MYPACKAGE::subname() calls the implementation of subname in MYPACKAGE
$result = $self->MYPACKAGE::subname('valid_input');
if ($result eq 'expected_output') {
    ;
} else {
    assert(0, "\$self->MYPACKAGE::subname() does not call MYPACKAGE implementation");
}

print "$0 - test passed!\n";
