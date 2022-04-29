# issue s68 - implement POSIX strftime
use Carp::Assert;
use POSIX "strftime";

# Example from documentation:


$str = POSIX::strftime( "%A, %B %d, %Y",
                         0, 0, 0, 12, 11, 95, 2 );
assert($str eq 'Tuesday, December 12, 1995');

# Example from tutorialspoint:

@t = (23, 10, 7, 16, 1, 113);
$datestring = strftime "%a %b %e %H:%M:%S %Y", @t;
assert($datestring eq 'Sat Feb 16 07:10:23 2013');

for($i = 0; $i < 2; $i++) {             # we could be off by 1 second so try twice
    $ds = strftime "%a %b %e %H:%M:%S %Y", localtime;
    $ct = localtime;
    last if($ds eq $ct);
}
assert($ds eq $ct);

# example from etas:

$logstamp=strftime("%m-%d-%y@%H:%M:%S", @t);
assert($logstamp eq '02-16-13@07:10:23');

print "$0 - test passed!\n";
