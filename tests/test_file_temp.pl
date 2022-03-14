# test of File::Temp

use Carp::Assert;
use File::Temp qw( tempfile tempdir :seekable :mktemp :POSIX );
#use POSIX;

my @junk = ();

my ($fh, $filename) = tempfile();
push @junk, $filename;
binmode( $fh, ":utf8" );
print $fh "message\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message\n");
assert($filename =~ /tmp/);

($fh, $filename) = tempfile('mytXXXX');
push @junk, $filename;
binmode( $fh, ":utf8" );
print $fh "message1\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message1\n");
assert($filename =~ /myt/);

($fh, $filename) = File::Temp::tempfile(SUFFIX=>'.dat');
push @junk, $filename;
binmode( $fh, ":utf8" );
print $fh "message2\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message2\n");
assert($filename =~ /\.dat$/);

$fh = File::Temp->new(TEMPLATE=>'tmpltXXXXX');
push @junk, $fh->filename;
binmode( $fh, ":utf8" );
print $fh "message3\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
assert($fh->filename =~ /tmplt/);
close($fh);
assert($line eq "message3\n");

$fh = new File::Temp(TEMPLATE=>'nmpltXXXXX');
push @junk, $fh->filename;
binmode( $fh, ":utf8" );
print $fh "message4\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
assert($fh->filename =~ /nmplt/);
close($fh);
assert($line eq "message4\n");

eval {
	require POSIX;
	$filename = POSIX::tmpnam();
	push @junk, $filename;
	open($fh, "+<", $filename);
	print $fh "message5\n";
	seek($fh, 0, SEEK_SET);
	my $line = <$fh>;
	close($fh);
	assert($line eq "message5\n");
	assert($filename =~ /tmp/);
};
# In perl: "Unimplemented: POSIX::tmpnam(): use File::Temp instead at test_file_temp.pl line 61."
assert($@ =~ /Unimplemented/) if $@;

my $tmpdir = File::Temp::newdir();
push @junk, $tmpdir;
($fh, $filename) = tempfile(DIR=>$tmpdir);
binmode( $fh, ":utf8" );
print $fh "message6\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
$tmpdir = quotemeta($tmpdir);
assert($filename =~ /$tmpdir/);
close($fh);
assert($line eq "message6\n");

$tmpdir = tempdir();
push @junk, $tmpdir;
$filename = "$tmpdir/my.file";
open($fh, "+>", $filename);
print $fh "message7\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message7\n");

$filename = mktemp('templateXXXXX');
push @junk, $filename;
open($fh, "+>", $filename);
print $fh "message8\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message8\n");
assert($filename =~ /template/);

($fh, $filename) = File::Temp::mkstemp('mypatXXXXX');
push @junk, $filename;
binmode( $fh, ":utf8" );
print $fh "message9\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message9\n");
assert($filename =~ /mypat/);

($fh, $filename) = mkstemps('mypatXXXXX', '.ext');
push @junk, $filename;
binmode( $fh, ":utf8" );
print $fh "message10\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message10\n");
assert($filename =~ /mypat/);
assert($filename =~ /\.ext$/);

$tmpdir = mkdtemp('tmpdirXXXXX');
push @junk, $tmpdir;
$filename = "$tmpdir/my.file";
open($fh, "+>", $filename);
print $fh "message11\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message11\n");
assert($tmpdir =~ /tmpdir/);

my $fh = tempfile();	# scalar context
#push @junk, $filename;
binmode( $fh, ":utf8" );
print $fh "message12\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message12\n");

$filename = File::Temp::tmpnam();	# scalar context
push @junk, $filename;
open($fh, "+>", $filename);
print $fh "message13\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message13\n");
assert($filename =~ /tmp/);

($fh, $filename) = File::Temp::tmpnam();	# list context
push @junk, $filename;
binmode( $fh, ":utf8" );
print $fh "message14\n";
seek($fh, 0, SEEK_SET);
my $line = <$fh>;
close($fh);
assert($line eq "message14\n");
assert($filename =~ /tmp/);

END {
    for my $f (@junk) {
	if(-d $f) {
	    opendir($dh, $f);
	    my @files = readdir($dh);
	    for my $g (@files) {
                my $fi = "$f/$g";
		eval {
		    unlink $fi;
	        };
	    }
	    eval {
	    	rmdir $f;
	    };
        } else {
	    eval {
	        unlink $f;
	    };
        }
    }
}

print("$0 - test passed!\n");
