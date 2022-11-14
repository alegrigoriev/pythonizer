# issue s164 - Passing a -pragma on a use statement is not translated correctly
use Carp::Assert;

use CGI qw(:standard -nph);

print "$0 - test passed!\n";
