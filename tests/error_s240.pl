# Non-implemented unicode properties
my $str = 'abc';

print "Should give 2 \\p errors and 2 \\P errors\n";
$str =~ /\p{Chakma}/;
$str =~ /\p{Math_Symbol}/;
$str =~ /[.\PN]/;
$str =~ /\P{Math_Symbol}/;

print "$0 - test passed\n";
