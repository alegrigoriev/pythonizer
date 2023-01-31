# issue s259 - caller() doesn't return the proper package name
package PackageA;

use Carp::Assert;

sub test_caller_scalar_context {
    # expected values
    my $expected_package = 'main';

    # call the caller() function in scalar context
    my $package = caller;

    # assert that the expected values match the actual values
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");

    # success
    return 1;
}

sub sub1 {
    my $expected_package = __PACKAGE__;

    my $package = caller;
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");
    assert($package eq 'PackageA', "Unexpected package name: $package, expected: PackageA");

    my $package = caller(1);
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");

    my @caller = caller(1);
    #print "@caller\n";
    assert($caller[0] eq $expected_package, "Unexpected package name: $caller[0], expected: $expected_package");
    assert($caller[1] eq $0, "Unexpected filename: $caller[1], expected: $0");
    assert($caller[3] =~ /sub2/, "Unexpected function name $caller[3], expected: to contain sub2");

    my $package = caller(2);
    $expected_package = 'main';
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");

    my $package = caller(3);
    $expected_package = undef;
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");
    return 1;
}

sub sub2 {
    my $expected_package = __PACKAGE__;

    my $package = caller(0);
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");

    my $caller_package = caller(1);
    assert($caller_package eq 'main', "Unexpected caller package name: $caller_package, expected: main");

    PackageA->sub1();
}

sub sub3 {
    #my $expected_package = __PACKAGE__;
    my $expected_package = 'main';

    my $package = caller(0);
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");

    my $caller_package = caller(1);
    assert(!defined $caller_package, "Unexpected caller package name: $caller_package, expected: undef");

    PackageA->sub2();
}

package main;
use Carp::Assert;
# Call the subroutines
assert(PackageA::sub3() == 1, 'Test case for sub3() failed');

package PackageB;

use Carp::Assert;

sub new_sub {
    my $expected_package = 'PackageB';
    my $package = caller;

    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");
}

sub new { 
    my $expected_package = 'PackageB';
    my $package = caller;

    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");
    new_sub();
    return bless {}, shift;
}
sub inner {
    my $expected_package = __PACKAGE__;
    my $package = caller;

    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");
}

sub test_caller_scalar_context_package_b {
    # expected values
    my $expected_package = 'main';

    # call the caller() function in scalar context
    my $package = caller;

    # assert that the expected values match the actual values
    assert($package eq $expected_package, "Unexpected package name: $package, expected: $expected_package");

    my $obj = new PackageB;
    $obj->inner();

    # success
    return 1;
}

package main;

# Call the two subroutines
assert(PackageA->test_caller_scalar_context() == 1, 'Test case for PackageA failed');
assert(PackageB->test_caller_scalar_context_package_b() == 1, 'Test case for PackageB failed');
print "$0 - test passed!\n";
