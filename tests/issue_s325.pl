# issue s325 - If a BEGIN block is defined before a use statement, the use statement is still run first
BEGIN {
    $ENV{issue_s325} = 'passed';
}
use lib '.';
use issue_s325m;

print "$0 - test passed!\n";
