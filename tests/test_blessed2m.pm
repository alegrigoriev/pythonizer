# part of test_blessed2
package test_blessed2m;
use strict;
use warnings;

use Carp::Assert;
no warnings 'experimental::builtin';
use builtin 'blessed';
use builtin qw/ceil floor/;

sub run_tests {
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

    # While we are here, test a couple more functions from builtin
    assert(ceil(2.5) == 3);
    assert(floor(2.5) == 2);
}

1;
