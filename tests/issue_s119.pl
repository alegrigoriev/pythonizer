# test log filename
use Carp::Assert;

($MonthDay,$Month,$Year)=(localtime)[3,4,5];
$Month=$Month+1;
$Year=$Year+1900;

if ($Month < 10) {
    $tm = "0$Month";
} else {
    $tm = $Month;
}
if ($MonthDay < 10) {
    $td = "0$MonthDay";
} else {
    $td = $MonthDay;
}
assert($tm =~ /\d{2}/);
assert($tm > 0 && $tm <= 12);
assert($td =~ /\d{2}/);
assert($td > 0 && $td <= 31);
assert($Year >= 2022);

$logFile = "log$tm$td$Year.txt";

assert($logFile =~ /log\d{8}\.txt/);
print "$0 - test passed!\n";
