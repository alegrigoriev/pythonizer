# issue s70a: Handle different file encodings properly
# -*- coding: cp1250 -*-
use Carp::Assert;
my $str = "–";      # en-dash
assert(ord $str == 0x96);
$str = "—";         # em-dash
assert(ord $str == 0x97);
print "$0 - test passed!\n";
