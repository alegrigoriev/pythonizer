# test the exporting of variables from another package.  This version does not import any subs, just the vars
# pragma pythonizer no implicit global my

use Carp::Assert;
use lib '.';
use ExportVars qw(:vars);

assert($xvar eq 'xvar');
assert(&ExportVars::get_xvar() eq 'xvar');
$xvar = 'newx';
assert($xvar eq 'newx');
assert(&ExportVars::get_xvar() eq 'newx');
assert($ExportVars::xvar eq 'newx');
assert(&ExportVars::get_xvar() eq 'newx');

assert($TABSTOP == 4);
$ExportVars::TABSTOP = 5;
assert($ExportVars::TABSTOP == 5);
assert($TABSTOP == 5);
$TABSTOP=6;
assert($TABSTOP == 6);
assert($ExportVars::TABSTOP == 6);

assert(@TABSTOP == 1);	# Try a name that needs to be mapped
assert($TABSTOP[0] == 4);

assert($in eq 'in');	# Try a name that needs to be escaped

assert(@xarr == 4);
my @arr = &ExportVars::get_xarr();
assert(@arr == 4);
assert($xarr[0] eq $arr[0] && $xarr[3] eq $arr[3]);
$xarr[0] = 'y';
assert($xarr[0] eq 'y');
@arr = &ExportVars::get_xarr();
assert($arr[0] eq 'y');

assert($xhash{x} eq 'h');
assert(%xhash == 3);
my %h = &ExportVars::get_xhash();
assert(%h == 3);
assert($h{x} eq 'h');
$xhash{h} = 'z';
assert($xhash{h} = 'z');
assert($ExportVars::xhash{h} = 'z');
%h = &ExportVars::get_xhash();
assert($h{h} eq 'z');

print "$0 - test passed!\n";
