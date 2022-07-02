# test type conversions on printf as seen in agntm.pl
use Carp::Assert;

open(FILE, '>', 'tmp.tmp');

my $key = 2;
$keyEquivc{'2'} = 1;
$flow_equivc{'1'} = '2000000';

printf FILE ("$key %.6f %.6f\n",
            $flow_equivc{$keyEquivc{$key}}/1e6,
            $flow_equivc{$keyEquivc{$key}}/1e6);

close(FILE);

open(FILE, '<', 'tmp.tmp');
$line = <FILE>;
assert($line eq "2 2.000000 2.000000\n");

END {
    eval { close(FILE) };
    eval { unlink "tmp.tmp" };
}

print "$0 - test passed!\n";
