# issue 35 - Expressions with multiple { } are not processed properly
#
use Carp::Assert;

$id = 'Id';
"date is 2022-02-05" =~ /(is )(\d+-\d+-\d+)/;
$tickets{$id}{date} = $2;

assert($tickets{Id}{date} eq "2022-02-05");

print "$0 - test passed!\n";
