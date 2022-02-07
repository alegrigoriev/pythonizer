# issue 62 - my @arr = <FH> generates incorrect code
#

use v5.10;
use Carp::Assert;

open(FH, "+>tmp.tmp");
say FH "line 1";
say FH "line 2";
say FH "line 3";
seek FH, 0, SEEK_SET;
my @arr = <FH>;
assert(3 == @arr);
assert($arr[0] eq "line 1\n");
assert($arr[1] eq "line 2\n");
assert($arr[2] eq "line 3\n");

print "$0 - test passed!\n";

END {
    eval {
        close(FH);
    };

    eval {
        unlink "tmp.tmp";
    };
}
