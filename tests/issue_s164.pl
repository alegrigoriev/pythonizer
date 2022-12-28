# issue s164 - Passing a -pragma on a use statement is not translated correctly
use Carp::Assert;
use lib '.';
use issue_s164m qw(:standard -nph);

use issue_s164m '-nph',':standard';

use issue_s164m -nph=>':standard';

assert($issue_s164m::import_called == 3);

print "$0 - test passed!\n";
