# Tests for IO::File and IO::Handle

use Carp::Assert;
use IO::File;

my $fh = IO::File->new();
$fh->binmode(':utf8');
$fh->open('tmp.tmp', '+>');
my $start = $fh->getpos;
$fh->print("output1\n");
$fh->setpos($start);
assert($fh->getc eq 'o');
$fh->ungetc(ord 'o');
$fh->read($buffer, 100);
assert($buffer eq "output1\n");
assert($fh->eof);
$fh->close;

$fh = IO::File->new_tmpfile;
$start = $fh->tell;
for(my $i=0; $i<10; $i++) {
    $fh->write($i,1);
}
$fh->seek($start, SEEK_SET);
my $j;
for(my $i=0; $i<10; $i++) {
    assert($fh->read($j,1) == 1);
    assert($i == $j);
}
assert($fh->read($j,1) == 0);	# no more
assert($fh->eof);
$fh->close;

$fh = IO::File->new_tmpfile;
$start = $fh->sysseek(0, SEEK_CUR);
for(my $i=0; $i<10; $i++) {
    $fh->syswrite($i,1);
}
$fh->sysseek($start, SEEK_SET);
my $j;
for(my $i=0; $i<10; $i++) {
    assert($fh->sysread($j,1) == 1);
    assert($i == $j);
}
assert($fh->sysread($j,1) == 0);	# no more
$fh->close;

print "$0 - test passed!\n";

