# error - \G regex assertion is not supported
use Carp::Assert;

$string = "The time is: 12:31:02 on 4/12/00";
$string =~ /:\s+/g;
($time) = ($string =~ /\G(\d+:\d+:\d+)/);
$string =~ /.+\s+/g;
($date) = ($string =~ m{\G(\d+/\d+/\d+)});
assert($time eq '12:31:02');
assert($date eq '4/12/00');

print "$0 - test passed!\n";
