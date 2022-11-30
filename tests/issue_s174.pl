# issue s174 - The .. (range) operator should be supported in initializations
# from CGI.pm
use Carp::Assert;

my @chrs = ('0'..'9', 'A'..'Z', 'a'..'z');
assert(@chrs == 26*2+10);
foreach (@chrs) {
    $chrs{$_} = 1;
}
assert(scalar(%chrs) == scalar(@chrs));
for ('0'..'9', 'A'..'Z', 'a'..'z') {
    assert(exists $chrs{$_});
    $tot++;
}
assert($tot == 26*2+10);

# Let's try numeric

my @numbers = (0..9, 100..102);
assert(@numbers == 13);
assert($numbers[0] == 0);
assert($numbers[1] == 1);
assert($numbers[9] == 9);
assert($numbers[10] == 100);
assert($numbers[-1] == 102);

print "$0 - test passed!\n";
