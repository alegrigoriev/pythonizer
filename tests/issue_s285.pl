# issue s285 - Use of uninitialized value $ValClass[1] in string eq
use Carp::Assert;

*SAVERR;

sub save_stderr {
    open(SAVERR, ">&STDERR") or print "Can't save STDERR";
}

sub restore_stderr {
    open(STDERR, ">&SAVERR") or print "Can't restore STDERR";
}

save_stderr();
close(STDERR);
restore_stderr();

print STDERR "$0 - test passed!\n";
