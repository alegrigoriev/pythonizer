# Subtest of test_global_namespace
use Carp::Assert;

sub func
{
    assert($initted eq "Initted");
    assert(!defined $here_only);
    assert($glob eq 'Global');
    assert(join('', @glob) eq 'Gl');
}
print "$0 - test passed!\n" unless(caller);
1;
