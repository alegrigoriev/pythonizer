# test no replace usage option (-U)
# pragma pythonizer no replace usage

use Carp::Assert;

my $usage = "Usage: test_replace_usage2.pl";

assert($usage eq 'Usage: test_replace_usage2.' . 'pl');


print "$0 - test passed!\n";
