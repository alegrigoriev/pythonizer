# issue s70b: Handle different file encodings properly
# -*- coding: cp1252 -*-
# This file is encoded using cp1252 (windows-1252), but it's not marked as such
use Carp::Assert;
my $str = "€";      # Euro sign
#printf "\\x%02x", ord $str;
assert(ord $str == 0x80);
assert(chr 0x80 eq $str);
$str = "…";         # Elipsis
#printf "\\x%02x", ord $str;
assert(ord $str == 0x85);
$str = "™";         # TM
#printf "\\x%02x", ord $str;
assert(ord $str == 0x99);
$str = "À";         # A-grave
assert(ord $str == 0xc0);
print "$0 - test passed!\n";
