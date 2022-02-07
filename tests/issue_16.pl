# issue 16 - ABEND: The number of generated chunk exceeed 256

use Carp::Assert;

$tmpdir = "/tmp";
$region = "region";
$hour = 12;

$bool = -e "$tmdir/$region/tm.wnet.$hour"
        	  or -e "$tmdir/$region/tm.wnet.$hour.Z";

assert(!$bool);

print "$0 - test passed!\n";
