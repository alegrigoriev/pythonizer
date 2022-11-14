# issue s151 - = ~ with extra space generates syntax error code
use Carp::Assert;

my $tmp = 'spgw_a';
my $neoRoot = '.';
my $date = 'today';
my $vendor = 'cisco';
if($tmp = ~/^spgw_\w/) {
    $cfgDir = "$neoRoot/$date/$vendor/spgw";
}
my $x = ($tmp = ~/^spgw_\w/);
#print "$x\n";
assert($x > 0);

assert($cfgDir eq './today/cisco/spgw');

print "$0 - test passed!\n";

