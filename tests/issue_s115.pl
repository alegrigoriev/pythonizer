# issue s115 - regex substitution of literal escape chars interprets them instead
# Issue found during bootstrap
use Carp::Assert;

my $tsnrb = 'tsnrb';
$tsnrb =~ s'tsnrb'\t \n\r\\';
assert($tsnrb eq '\t \n\r\\');
$tsnrb = 'tsnrb';
$tsnrb =~ s/tsnrb/\t \n\r\\/;
assert($tsnrb eq "\t \n\r\\");

print "$0 - test passed\n";
