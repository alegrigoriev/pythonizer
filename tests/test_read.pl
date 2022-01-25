# Test the 'read' command
# read FILEHANDLE,SCALAR,LENGTH,OFFSET 
# read FILEHANDLE,SCALAR,LENGTH

use Carp::Assert;

my $scalar;
open(FH, '>tmp.tmp');
print FH "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ\n";
close(FH);
open(FH, '<tmp.tmp');
read FH, $scalar, 1;
assert($scalar eq '0');
read(FH, $scalar, 2);
assert($scalar eq '12');
my @arr=('');
read FH, $arr[0], 1;
assert($arr[0] eq '3');
read FH, $arr[0], 1, 1;
assert($arr[0] eq '34');
read FH, $global, 1;
assert($global eq '5');
assert(read(FH, $global, 1) == 1);
assert($global eq '6');
assert(read(FH, $global, 2, 0) == 2);
assert($global eq '78');
my %hash=(key=>1);
read(FH, $scalar, $hash{key});
assert($scalar eq '9');
assert(read(FH, $scalar, 1) == 1);
assert($scalar eq 'A');
assert(read(FH, $scalar, $hash{key}) == 1);
assert($scalar eq 'B');
assert(read(FH, $arr[0], $hash{key}+1) == 2);
assert($arr[0] eq 'CD');
my $bytes = 4;
my $pos = 1;
read FH, $global, $bytes, $pos;
assert($global eq '7EFGH');
read FH, $global, 2, $pos+1;
assert($global eq '7EIJ');
read FH, $global, 2, 6;
assert($global eq "7EIJ\0\0KL");
close(FH);
assert(!defined read(FH, $global, 1));
assert($! =~ /Bad file descriptor/ || $! =~ /closed file/);

open my $fh, '<tmp.tmp';
assert(read($fh, $scalar, 2) == 2);
assert($scalar eq '01');
assert(read($fh, $scalar,2, 2) == 2);
assert($scalar eq '0123');
my $offset = 4;
assert(($got = read($fh, $scalar, 2, $offset)) == 2);
assert($got == 2);
assert($scalar eq '012345');
my %off = (key=>6);
assert(read($fh, $scalar, 3, $off{key}) == 3);
assert($scalar eq '012345678');
assert(read($fh, $global, 2, 2) == 2);
assert($global eq '7E9A');
assert(read($fh, $global, 100, 8) == 26);
assert($global eq "7E9A\0\0\0\0BCDEFGHIJKLMNOPQRSTUVWXYZ\n");
$offset = 0;
assert(read($fh, $global, 1, $offset) == 0);	# EOF
assert($global eq '');
assert(read($fh, $arr[0], 1, $offset) == 0);	# EOF
assert($arr[0] eq '');
assert(read($fh, $local, 1) == 0);		# EOF
assert($local eq '');
close($fh);

# Currently 'open' doesn't support this!!
#open($arr[0], '<tmp.tmp');
#read($arr[0], $scalar, 1);
#assert($scalar eq '0');
#assert(read($arr[0], $scalar, 1) == 1);
#assert($scalar eq '1');
#assert(read($arr[0], $global, 2) == 2);
#assert($global eq '23');
#close($arr[0]);
print "$0 - test passed!\n";

END {                   # Clean up!
    eval {close(FH)};
    #eval {close($arr[0])};
    eval {unlink 'tmp.tmp'};
}



