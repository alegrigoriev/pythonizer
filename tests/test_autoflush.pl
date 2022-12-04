# Test the autoflush option
use Carp::Assert;

assert(STDOUT->autoflush(0) == 0);
assert(STDERR->autoflush(0) == 0);

open(STDOUT, '>tmp.tmp');
print "Here is some output";
open(FH, '<tmp.tmp');
$line = <FH>;
assert(!$line);
close(FH);

$| = 1;

print " more";
open(FH, '<tmp.tmp');
$line = <FH>;
assert($line eq "Here is some output more");
close(FH);

# Try it with binmode
binmode(STDOUT);
print " and more in binary";
open(FH, '<tmp.tmp');
$line = <FH>;
assert($line eq "Here is some output more and more in binary");
close(FH);
close(STDOUT);
$| = 0;

open(STDOUT, '>tmp.tmp');
print "Here is some output";
open(FH, '<tmp.tmp');
$line = <FH>;
assert(!$line);
close(FH);
close(STDOUT);

open(STDOUT, '>tmp.tmp');
assert(STDOUT->autoflush(1) == 0);
print "Here is some output";
open(FH, '<tmp.tmp');
$line = <FH>;
assert($line eq "Here is some output");
close(FH);

open(OUT, '>tmp.tmp');
print OUT "Here is some output";
open(FH, '<tmp.tmp');
$line = <FH>;
assert(!$line);
close(FH);
# If set to nonzero, forces a flush right away and after every write or print on the currently selected output channel.
$| = 1;
# That means the following should NOT be autoflushed:
print OUT " more";
open(FH, '<tmp.tmp');
$line = <FH>;
assert(!$line);
close(FH);
assert(OUT->autoflush(1) == 0);
print OUT " and more";

open(FH, '<tmp.tmp');
$line = <FH>;
assert($line eq "Here is some output more and more");
close(FH);
assert(OUT->autoflush(1) == 1);
close(OUT);

#assert(STDERR->autoflush() == 0);       # Default is 1
#assert(STDERR->autoflush(0) == 1);
END {
    close(STDOUT);
    close(FH);
    eval {close(OUT);};
    eval {unlink "tmp.tmp";};
}

say STDERR "$0 - test passed!";
