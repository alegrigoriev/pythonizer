# Reserved word 'in' used as file handle in diamond operator needs to be escaped
use Carp::Assert;

open($in, "<", "$0");

my $line = <$in>;

assert($line =~ /^#/);
close($in);

# Let's try a bare one

open(in, "<", "$0");

my $line = <in>;

assert($line =~ /^#/);
close(in);

print "$0 - test passed!\n";
