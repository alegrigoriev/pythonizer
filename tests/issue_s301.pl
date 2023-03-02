# issue s301 - Implement tie scalar
use Carp::Assert;
use lib '.';
use TiedScalar;

my $scalar = tie $tied_scalar, 'TiedScalar', 42;

assert($scalar->FETCH() == 42, "explicit FETCH returns correct initial value");
assert($tied_scalar == 42, "implicit FETCH returns correct initial value");
assert($tied_scalar, "implicit FETCH returns correct boolean value");

$tied_scalar = 0;
assert(!$tied_scalar, "implicit FETCH w/0 value returns correct boolean value");

$tied_scalar = 99;
assert($scalar->FETCH() == 99, "STORE sets new value correctly");
assert($tied_scalar+1 == 100, "FETCH gets the right value");

$tied_scalar = "hello";
assert($scalar->FETCH() eq "hello", "STORE sets new value correctly");

$tied_scalar = undef;
assert(!defined $scalar->FETCH(), "STORE sets value to undef");


eval { $scalar->UNDEFINED_METHOD() };
assert($@ =~ /Can't locate object method/ || $@ =~ /object has no attribute/, "Calling undefined method throws error");

assert($TiedScalar::FETCH_CALLED == 8, "FETCH_CALLED is $TiedScalar::FETCH_CALLED != 8");
assert($TiedScalar::STORE_CALLED == 4, "STORE_CALLED is $TiedScalar::STORE_CALLED != 4");
untie $tied_scalar;
assert($TiedScalar::UNTIE_CALLED == 1, "UNTIE_CALLED is $TiedScalar::UNTIE_CALLED != 1");

$tied_scalar = 42;
assert($tied_scalar == 42, "Scalar value wrong after untie");
assert($TiedScalar::FETCH_CALLED == 8, "FETCH_CALLED is $TiedScalar::FETCH_CALLED != 8 after untie");
assert($TiedScalar::STORE_CALLED == 4, "STORE_CALLED is $TiedScalar::STORE_CALLED != 4 after untie");

#tie my $second_scalar, TiedScalar, 0;
my %hash = (key=>'TiedScalar');
tie my $second_scalar, $hash{key}, 0;
assert($second_scalar == 0, "my Second scalar doesn't work");

assert($TiedScalar::FETCH_CALLED == 9, "FETCH_CALLED is $TiedScalar::FETCH_CALLED != 9");
assert($TiedScalar::STORE_CALLED == 4, "STORE_CALLED is $TiedScalar::STORE_CALLED != 4");

my $pkg = __PACKAGE__;
my $name = 'scalar_name';
tie ${"${pkg}::$name"}, TiedScalar, $name;
assert($scalar_name eq 'scalar_name', "\$scalar_name is not scalar_name");
$scalar_name = 'new name';
assert($scalar_name eq 'new name', "\$scalar_name is not new name");
assert($TiedScalar::FETCH_CALLED == 11, "FETCH_CALLED is $TiedScalar::FETCH_CALLED != 13");
assert($TiedScalar::STORE_CALLED == 5, "STORE_CALLED is $TiedScalar::STORE_CALLED != 5");

print "$0 - test passed!\n";
