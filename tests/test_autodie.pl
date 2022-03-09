# Test the autodie option

use v5.10;
use Carp::Assert;
use IO::File;
use autodie qw(:all);

$SIG{__WARN__} = sub{};

$py = ($0 =~ /\.py$/);

open(FH, '<', $0);
close(FH);

eval {
    open(FH, '<', 'non-exist.file');
};
assert($@ =~ /exist/);

#undef $@;
#eval {
#close FH;
#};
#assert($@ =~ /close/);

undef $@;
eval {
    opendir(DH, 'non-exist.dir');
};
assert($@ =~ /exist/);

undef $@;
eval {
    `badcommand`;
};
assert($@ =~ /badcommand/) if($py);

undef $@;
eval {
    my $result = `badcommand`;
};
#print "backtick2: $@\n";
assert($@ =~ /badcommand/) if($py);

undef $@;
eval {
    my $bad = "badcommand";
    system "$bad";
};
#print "system: $@\n";
assert($@ =~ /badcommand/);

undef $@;
eval {
    my $bad = "badcommand";
    qx/$bad/;
};
#print "qx: $@\n";
assert($@ =~ /badcommand/) if($py);

undef $@;
eval {
    print FH "text\n";
};
#print "print: $@\n";
assert($@ =~ /closed/) if($py);

undef $@;
eval {
    say FH "text\n";
};
#print "say: $@\n";
assert($@ =~ /closed/) if($py);

undef $@;
eval {
    read(FH, $buf, 1);
};
assert($@ =~ /closed/ || $@ =~ /Bad file/);

undef $@;
eval {
    sysread(FH, $buf, 1);
};
assert($@ =~ /closed/ || $@ =~ /Bad file/);

undef $@;
eval {
    mkdir ".";
};
assert($@ =~ /exists/);

undef $@;
eval {
    seek(FH, 0, 0);
};
assert($@ =~ /closed/ || $@ =~ /Bad file/);

undef $@;
eval {
    tell(FH);
};
#print "tell: $@\n";
assert($@ =~ /closed/) if($py);

undef $@;
eval {
    truncate FH, 0;
};
assert($@ =~ /closed/ || $@ =~ /No such file/);

undef $@;
eval {
    truncate "not.exist", 0;
};
assert($@ =~ /No such/);

print "$0 - test passed!\n";
