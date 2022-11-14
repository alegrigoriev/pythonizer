# issue s165 - Bogus pattern match operation generates TypeError in python
use Carp::Assert;

my $bogus_cmd = 'oops';

$ret_code = system($bogus_cmd);
$ret_code=~$?>>8;           # Bogus pattern match operation
assert($ret_code);

print "$0 - test passed!\n";
