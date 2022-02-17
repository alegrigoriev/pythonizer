# issue 118 - qx or backtick in list context

use Carp::Assert;

$s = ($^O eq 'MSWin32') ? '&' : ';';

$command = "echo line1${s}echo line2${s}echo line3";

@a = `$command`;
assert(@a == 3 && $a[0] eq "line1\n" && $a[1] eq "line2\n" && $a[2] eq "line3\n");
$s = `$command`;        # scalar context
assert($s eq  "line1\nline2\nline3\n");

($l1, $l2, $l3) = `$command`;
assert($l1 eq "line1\n");
assert($l2 eq "line2\n");
assert($l3 eq "line3\n");

foreach (qx/$command/) {
    assert(($v) = /^line(\d)/);
    $tot += $v;
}
assert($tot == 6);

print "$0 - test passed!\n";
