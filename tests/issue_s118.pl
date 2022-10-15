# issue s118 - split of the result of a command execution never runs the command
use Carp::Assert;

$tmpDir = ".";
my ($noRtrs, $tmp) =  split(" ",`wc -l $tmpDir/$0`);

assert($noRtrs >= 10);
assert($tmp =~ /issue_s118/);

print "$0 - test passed!\n";
