# issue 65 - reverse is not implemented
use Carp::Assert;
@arr = ("world", "Hello");
@hwa = reverse @arr;
assert($hwa[0] eq 'Hello' && $hwa[1] eq 'world');
@hwb = reverse sort @arr;
assert($hwb[1] eq 'Hello' && $hwb[0] eq 'world');
$hw = join(", ", reverse "world", "Hello");
assert($hw eq 'Hello, world');
$hw = reverse "dlrow ,", "olleH";
assert($hw eq 'Hello, world');
$_ = "dlrow ,olleH";
$hw = reverse;
assert($hw eq 'Hello, world');
%fw = (key1=>'val1', key2=>'val2');
my %rev = reverse %fw;	# invert the hash
assert($rev{val1} eq 'key1' && $rev{val2} eq 'key2');
print "$0 - test passed!\n";
