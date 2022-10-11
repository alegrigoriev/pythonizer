# issue s112 - string containing only '.pl' should not be changed to '.py'
use Carp::Assert;

my $pl1 = '.pl';
$pl2 = ".pl";

assert($pl1 eq ('.p' . 'l'));
assert($pl2 eq ('.p' . 'l'));

print "$0 - test passed!\n";
