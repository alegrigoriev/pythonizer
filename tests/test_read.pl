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
close(FH);

open my $fh, '<tmp.tmp';
assert(read($fh, $scalar, 2) == 2);
assert($scalar eq '01');
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



