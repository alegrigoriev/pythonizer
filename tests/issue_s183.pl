# issue s183 - Calling binmode on a sub argument generates bad code
# code from CGI.pm
use Carp::Assert;
my $debug = 0;

# put a filehandle into binary mode (DOS)
sub do_binmode {
    return unless defined($_[0]) && ref ($_[0]) && defined fileno($_[0]);
    CORE::binmode($_[0]);
}

sub do_open {
    open($_[0], $_[1], $_[2]);
    $_[0];
}

sub do_read {
    read($_[0], $_[1], $_[2]);
    $_[1];
}

#open(my $fh, '>', 'tmp.tmp') or die "Cannot create tmp.tmp";
my $fh;
$fh = do_open($fh, '>', 'tmp.tmp') or die "Cannot create tmp.tmp";
do_binmode($fh);
$buff = "\0\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27";
print $fh $buff;
close($fh);

#open($fh, '<', 'tmp.tmp') or die "Cannot open tmp.tmp";
$fh = do_open($fh, '<', 'tmp.tmp') or die "Cannot open tmp.tmp";
do_binmode($fh);
#read($fh, my $data, 100);
my $data;
$data = do_read($fh, $data, 100);
if($debug) {
    for(my $i=0; $i < length($buff); $i++) {
        print ord(substr($buff,$i,1));
        print ' ';
    }
    print "\n";
    for(my $i=0; $i < length($data); $i++) {
        print ord(substr($data,$i,1));
        print ' ';
    }
    print "\n";
}
assert($data eq $buff);


# test some more functions with out parameters
sub chop_all {
    chop(@_);
}
my $v1 = "v\n";
my $v2 = "2\n";
chop_all($v1, $v2);

sub do_chomp  {
    chomp($_[0]);
}
my $v = "v\n";
assert(do_chomp($v) == 1);

sub do_sysread {
    sysread($_[0], $_[1], $_[2]);
    $_[1];
}
sysseek($fh, 0, 0);
my $sdata;
$sdata = do_sysread($fh, $sdata, 100);
assert($sdata eq $buff);
close($fh);

# Test how the implicit return adjusts these calls w/out parameters
sub open_last {
    open($_[0], $_[1]);
}

sub read_last {
    read($_[0], $_[1], $_[2]);
}

sub sysread_last {
    sysread($_[0], $_[1], $_[2]);
}

sub returnBadFH
{
    open(FILE, '<noSuchFile');
}
$status = returnBadFH();
assert(!$status);

# Test _perl_print sep and end options on binary files
# Note: autoflush is tested in test_autoflush
$fh = do_open($fh, '>', 'tmp.tmp') or die "Cannot create tmp.tmp";
do_binmode($fh);
$, = ', ';      # OUTPUT_FIELD_SEPARATOR
$\ = "\n";      # OUTPUT_RECORD_SEPARATOR
print $fh 'abc', 'def', 'ghi';
print $fh 'x', 'y';
close($fh);

open($fh, '<tmp.tmp') or die 'Cannot open tmp.tmp';
@arr = <$fh>;
assert(scalar(@arr) == 2);
assert($arr[0] eq "abc, def, ghi\n");
assert($arr[1] eq "x, y\n");
close($fh);

print "$0 - test passed!";  # No \n because of $\

END {
    unless($debug) {
        eval { close($fh) };
        eval { unlink "tmp.tmp" };
    }
}
