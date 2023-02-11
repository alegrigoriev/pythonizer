# issue s272a - $DB::single = 1; shouldn't jump into the debugger if -mpdb isn't specified on the python command, even if we're using the -P option
# pragma pythonizer -P
use Carp::Assert;
$DB::single = 1;
print "$0 - test passed!\n";
