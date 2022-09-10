# issue s99 - if you have more formats than items, you get an error in python but not perl
use Carp::Assert;

my $r = sprintf("%s");
assert($r eq '');
$r = sprintf("%.3f");
assert($r eq '0.000');
$r = sprintf("%d,%d", 6);
assert($r eq '6,0');
$r = sprintf("%.3f,%.3f", 7.5);
assert($r eq '7.500,0.000');
$r = sprintf("%s,%s,%s", 'abc');
assert($r eq 'abc,,');

print "$0 - test passed!\n";
