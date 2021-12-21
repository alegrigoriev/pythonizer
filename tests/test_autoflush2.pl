# Test the autoflush option without using $|
use Carp::Assert;

assert(STDOUT->autoflush(0) == 0);
assert(STDOUT->autoflush() == 0);       # Default is 1
assert(STDERR->autoflush(0) == 0);
assert(STDERR->autoflush() == 0);
assert(STDERR->autoflush(0) == 1);

STDOUT->autoflush(1);

# These forms were generating translation errors
open(FD, '>tmp.tmp');
FD->autoflush(1);
close(FD);

open($fh, '>tmp.tmp');
$fh->autoflush();
close($fh);

END {                   # Clean up!
    eval {close(FD);};
    eval {close($fh);};
    eval{unlink "tmp.tmp";};
}

say STDERR "$0 - test passed!";
