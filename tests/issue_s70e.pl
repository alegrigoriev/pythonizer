# issue s70e: Handle different file encodings properly
# This file is encoded using cp1252 (windows-1252), but it's not marked as such
# In this case we use utf8 for the output file
# pragma pythonizer -me cp-1252,
use Carp::Assert;
my $py = ($0 =~ /.py$/);
my $str = "€";      # Euro sign
#printf "\\x{%04x}", ord $str;
if($py) {
    assert(ord $str == 0x20ac);
    assert(chr 0x20ac eq $str);
} else {
    assert(ord $str == 0x80);
    assert(chr 0x80 eq $str);
}
$str = "…";         # Elipsis
#printf "\\x{%04x}", ord $str;
if($py) {
    assert(ord $str == 0x2026);
} else {
    assert(ord $str == 0x85);
}
$str = "™";         # TM
#printf "\\x{%04x}", ord $str;
if($py) {
    assert(ord $str == 0x2122);
} else {
    assert(ord $str == 0x99);
}
$str = "À";         # A-grave
#printf "\\x{%04x}", ord $str;
assert(ord $str == 0xc0);   # Same in both!
print "$0 - test passed!\n";
