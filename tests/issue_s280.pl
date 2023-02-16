# issue_s280 - Explicitly calling Exporter::import doesn't work
# pragma pythonizer -M
use lib '.';
use issue_s280m;
use Carp::Assert;

assert(mysub() == 42);

print "$0 - test passed!\n";
