# test the exporting of variables from another package.  This version doesn't import anything and refers to everything
# with the package name.
# pragma pythonizer no implicit global my

use Carp::Assert;
use lib '.';
use ExportVars ();

assert($ExportVars::xvar eq 'xvar');
assert(&ExportVars::get_xvar() eq 'xvar');
$ExportVars::xvar = 'newx';
assert($ExportVars::xvar eq 'newx');
assert(&ExportVars::get_xvar() eq 'newx');
assert($ExportVars::xvar eq 'newx');
assert(&ExportVars::get_xvar() eq 'newx');

assert($ExportVars::TABSTOP == 4);
$ExportVars::TABSTOP = 5;
assert($ExportVars::TABSTOP == 5);
assert($ExportVars::TABSTOP == 5);
$ExportVars::TABSTOP=6;
assert($ExportVars::TABSTOP == 6);
assert($ExportVars::TABSTOP == 6);

assert(@ExportVars::TABSTOP == 1);	# Try a name that needs to be mapped
assert($ExportVars::TABSTOP[0] == 4);

assert($ExportVars::in eq 'in');	# Try a name that needs to be escaped

assert(@ExportVars::xarr == 4);
my @arr = &ExportVars::get_xarr();
assert(@arr == 4);
assert($ExportVars::xarr[0] eq $arr[0] && $ExportVars::xarr[3] eq $arr[3]);
$ExportVars::xarr[0] = 'y';
assert($ExportVars::xarr[0] eq 'y');
@arr = &ExportVars::get_xarr();
assert($arr[0] eq 'y');

assert($ExportVars::xhash{x} eq 'h');
assert(%ExportVars::xhash == 3);
my %h = &ExportVars::get_xhash();
assert(%h == 3);
assert($h{x} eq 'h');
$ExportVars::xhash{h} = 'z';
assert($ExportVars::xhash{h} = 'z');
%h = &ExportVars::get_xhash();
assert($h{h} eq 'z');

print "$0 - test passed!\n";
