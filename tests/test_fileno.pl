# test the fileno function
use Carp::Assert;

open(FH, "<", $0);

$fn = fileno(FH);
assert($fn > 2 && $fn < 255);

close(FH);
assert(!defined fileno(FH));

opendir(DH, '.');
$py = ($0 =~ /\.py$/);
assert(!defined fileno(DH)) if $py;

print "$0 - test passed!\n";
