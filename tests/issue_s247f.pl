# issue s247f - check that exec flushes open files
use Carp::Assert;
no warnings 'experimental';

# Check if the program is being called with the 'check' argument
if ("check" ~~ @ARGV) {
    #check if the contents of the file are as expected
    open(my $rfh, '<', 'tmp.tmp') or die $!;
    my $contents = do { local $/; <$rfh> };
    close $rfh;
    unlink 'tmp.tmp';
    assert($contents eq "Data to be flushed");
    print STDERR "$0 - test passed!\n";
} else {
    # Open a file handle (Pythonizer only flushes STDOUT and STDERR)
    close(STDOUT);
    open(STDOUT, '>', 'tmp.tmp') or die $!;

    # Write some data to the file handle
    print "Data to be flushed";
    # exec the program with the 'check' argument
    exec($^X, $0, 'check') or die "exec failed $!";
}
