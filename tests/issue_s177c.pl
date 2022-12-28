# issue s177c - The import function should be called in the translation of use statements
use Carp::Assert;
use lib '.';
use issue_s177m -a2=>'a1';

assert(scalar(@issue_s177m::import_args) == 3);
assert($issue_s177m::import_args[0] eq 'issue_s177m');
assert($issue_s177m::import_args[1] eq '-a2');
assert($issue_s177m::import_args[2] eq 'a1');

assert(a1() == 1);

print "$0 - test passed!\n";
