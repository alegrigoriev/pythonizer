# issue s325a - If a BEGIN block is defined before a use statement, the use statement is still run first
# This test is uses a BEGIN block that defines an explicit package variable, so it must be run after the
# init_package("main") call, and it doesn't qualify for special treatment

BEGIN {
    $main::my_var = 1;
}
# pragma pythonizer -M
use Carp::Assert;

assert($my_var == 1);

print "$0 - test passed!\n";
