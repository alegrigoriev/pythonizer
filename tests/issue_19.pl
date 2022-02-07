# issue 19 - Subexpression parens are missing on postfix control

use Carp::Assert;

$cttdir = "/nope";
$hour = 14;

print "found snmp data for hour $hour\n" 
     if (-f "$cttdir/bytes.$hour" or -f "$cttdir/bytes.$hour.Z")
        and $options{debug};

print "$0 - test passed\n";
