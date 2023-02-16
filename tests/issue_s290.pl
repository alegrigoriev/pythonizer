# issue s290 - assert statement with side-effect generates assert that's always True
use Carp::Assert;

eval {
    assert($assert_executed++, "operation expected to fail");
};

assert($@ =~ /operation expected to fail/);     # It should fail because $assert_executed is 0 (then post-incremented)

print "$0 - test passed!\n";
