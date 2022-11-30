# issue s177b - The import function should be called in the translation of use statements
use Carp::Assert;
use lib '.';
use issue_s177m v1.0;

assert(scalar(@issue_s177m::import_args) == 1);
assert($issue_s177m::import_args[0] eq 'issue_s177m');

assert(!defined &a1);

print "$0 - test passed!\n";
