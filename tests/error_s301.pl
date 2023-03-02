# error_s301 - test tie scalar with -m option (not supported)
# pragma pythonizer -m
use lib '.';
use TiedScalar;

tie my $error, TiedScalar;

print "$0 - test passed!\n";
