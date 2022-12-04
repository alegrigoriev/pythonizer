# issue s187 - use MODULE (); should not call the import method
use Carp::Assert;

use lib '.';
use issue_s187m ();

issue_s187m::print_it "$0 - test passed!\n";
