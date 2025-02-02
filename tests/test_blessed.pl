# test blessed
package Some::Package;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

package Some::Package::Subclass;
use parent '-norequire'=>'Some::Package';

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

package main;
use Carp::Assert;
use Scalar::Util qw(blessed);

# Test 1: Check that blessed function returns the correct package name for an object
my $obj1 = Some::Package->new;
assert(blessed($obj1) eq 'Some::Package');

# Test 2: Check that blessed function returns undef for a non-object reference
my $array_ref = [1, 2, 3];
assert(!defined blessed($array_ref));

# Test 3: Check that blessed function returns the correct package name for a subclass object
my $obj2 = Some::Package::Subclass->new;
assert(blessed($obj2) eq 'Some::Package::Subclass');

# Test 4: Check that blessed function returns undef for an unblessed reference
my $unblessed_ref = {};
assert(!defined blessed($unblessed_ref));

print "$0 - test passed!\n";
