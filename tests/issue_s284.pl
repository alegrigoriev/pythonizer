# issue s284 - add an option to fully qualify method calls
# pragma pythonizer -Mf

use Carp::Assert;

sub test_sub { 1 }

assert(test_sub() == 1);
assert(&test_sub() == 1);
assert(::test_sub() == 1);
assert(&::test_sub() == 1);
assert(main::test_sub() == 1);
assert(&main::test_sub() == 1);

sub subtest {
    local *main::test_sub = sub { 0 };

    assert(test_sub() == 0);
    assert(&test_sub() == 0);
    assert(::test_sub() == 0);
    assert(&::test_sub() == 0);
    assert(main::test_sub() == 0);
    assert(&main::test_sub() == 0);
}

subtest();

# Check that the 'local' worked
assert(&main::test_sub() == 1);

print "$0 - test passed!\n";
