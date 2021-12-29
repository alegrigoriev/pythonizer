# Subtest of test_global_namespace
#
use Carp::Assert;

$initted = "not!";
my $here_only = "init";
my $file = "initFile";
assert($initted eq 'not!');
assert($here_only eq 'init');
assert($file eq 'initFile');

print "$0 - test passed!\n" unless(caller);
1;
