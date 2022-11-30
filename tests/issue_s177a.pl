# issue s177a - The import function should be called in the translation of use statements
use Carp::Assert;
use lib '.';
use issue_s177m ('a1', '-a2');

assert(scalar(@issue_s177m::import_args) == 3);
assert($issue_s177m::import_args[0] eq 'issue_s177m');
assert($issue_s177m::import_args[1] eq 'a1');
assert($issue_s177m::import_args[2] eq '-a2');

assert(a1() == 1);

print "$0 - test passed!\n";
