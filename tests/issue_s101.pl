# issue s101 - missing global for file handle across subs
# defect found in qosbytes.pl
# pragma pythonizer -m
use Carp::Assert;

sub makebytes
{
    open(BYTESFILE, ">tmp.tmp") or die("cannot open tmp.tmp $!");
    makecbbbytes();
    close(BYTESFILE);
}

sub makecbbbytes
{
    writebytefile();
}

sub writebytefile
{
    print BYTESFILE "output\n";
}

sub checkbytes
{
    close(STDERR);
    open STDERR, ">>tmp.tmp";
    warn "test warn";	# Test warn because we changed the python mapping table for it
    close(STDERR);
    open(FILE, "<tmp.tmp");
    $content = <FILE>;
    assert($content eq "output\n");
    $warn = <FILE>;
    assert($warn =~ /test warn/);
    print "$0 - test passed!\n";
}

END {
	close(FILE);
	unlink "tmp.tmp";
}

makebytes();
checkbytes();
