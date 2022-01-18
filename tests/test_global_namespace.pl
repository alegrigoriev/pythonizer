# Test perl global namespace
#

$glob = "Global";
@glob = ('G', 'l');
my $file = "File";
require "./test_global_namespaceInit.pl";
require "./test_global_namespaceFunc.pl";
require "./test_global_namespacePackage.pl";
use lib '.';
use Exporting qw(frobnicate);

$initted = "Initted";

assert($file eq 'File');

func();

sub checkit
{
    assert($glob eq 'Global');
    assert($initted eq 'Initted');
    assert(!defined $here_only);
}

assert($glob eq 'Global');
assert($initted eq 'Initted');
assert(!defined $here_only);

checkit();

&pack::check_pack();

assert(frobnicate('rob') eq 'frob');

print "$0 - test passed!\n";
