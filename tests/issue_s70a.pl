# issue s70a: Handle different file encodings properly
# This file is encoded using cp1250 (windows-1250), but it's not marked as such
use Carp::Assert;
my $str = "–";      # en-dash
assert(ord $str == 0x96);
$str = "—";         # em-dash
assert(ord $str == 0x97);
print "$0 - test passed!\n";
