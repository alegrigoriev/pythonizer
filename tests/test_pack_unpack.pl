# test pack and unpack
use Carp::Assert;

#$foo = pack("WWWW",65,66,67,68);
$foo = pack("CCCC",65,66,67,68);
# foo eq "ABCD"
assert($foo eq "ABCD");
assert(join(',', unpack "CCCC", $foo) eq '65,66,67,68');
#$foo = pack("W4",65,66,67,68);
$foo = pack("C4",65,66,67,68);
assert($foo eq "ABCD");
assert(join(',', unpack "C4", $foo) eq '65,66,67,68');
# same thing
#$foo = pack("W4",0x24b6,0x24b7,0x24b8,0x24b9);
# same thing with Unicode circled letters.
#$foo = pack("U4",0x24b6,0x24b7,0x24b8,0x24b9);
# same thing with Unicode circled letters.  You don't get the
# UTF-8 bytes because the U at the start of the format caused
# a switch to U0-mode, so the UTF-8 bytes get joined into
# characters
#$foo = pack("C0U4",0x24b6,0x24b7,0x24b8,0x24b9);
# foo eq "\xe2\x92\xb6\xe2\x92\xb7\xe2\x92\xb8\xe2\x92\xb9"
# This is the UTF-8 encoding of the string in the
# previous example

$foo = pack("ccxxcc",65,66,67,68);
# foo eq "AB\0\0CD"
assert($foo eq "AB\0\0CD");
assert(join(',', unpack "ccxxcc", $foo) eq '65,66,67,68');

# NOTE: The examples above featuring "W" and "c" are true
# only on ASCII and ASCII-derived systems such as ISO Latin 1
# and UTF-8.  On EBCDIC systems, the first example would be
#      $foo = pack("WWWW",193,194,195,196);

$foo = pack("s2",1,2);
# "\001\000\002\000" on little-endian
# "\000\001\000\002" on big-endian
assert($foo eq "\001\000\002\000" || $foo eq "\000\001\000\002");
assert(join(',', unpack "s2", $foo) eq '1,2');

$foo = pack("a4","abcd","x","y","z");
# "abcd"
assert($foo eq 'abcd');
assert(join(',', unpack "a4", $foo) eq 'abcd');

$foo = pack("aaaa","abcd","x","y","z");
# "axyz"
assert($foo eq 'axyz');
assert(join(',', unpack "aaaa", $foo) eq 'a,x,y,z');

$foo = pack("a14","abcdefg");
# "abcdefg\0\0\0\0\0\0\0"
assert($foo eq "abcdefg\0\0\0\0\0\0\0");

#$foo = pack("i9pl", gmtime);
# a real struct tm (on my system anyway)

#$utmp_template = "Z8 Z8 Z16 L";
#$utmp = pack($utmp_template, @utmp1);
# a struct utmp (BSDish)

#@utmp2 = unpack($utmp_template, $utmp);
# "@utmp1" eq "@utmp2"

sub bintodec {
    unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

#print bintodec(42) . "\n";

$foo = pack('sx2l', 12, 34);
# short 12, two zero bytes padding, long 34
#print "$foo\n";
assert(join(',', unpack('sx2l', $foo)) eq '12,34');
#$bar = pack('s@4l', 12, 34);
# short 12, zero fill to position 4, long 34
# $foo eq $bar
#print "$bar\n";
#$baz = pack('s.l', 12, 4, 34);
# short 12, zero fill to position 4, long 34
#print "$baz\n";

$foo = pack('nN', 42, 4711);
# pack big-endian 16- and 32-bit unsigned integers
#print "$foo\n";
assert(join(',', unpack('nN', $foo)) eq '42,4711');
$foo = pack('S>L>', 42, 4711);
# exactly the same
#print "$foo\n";
assert(join(',', unpack('S>L>', $foo)) eq '42,4711');
$foo = pack('s<l<', -42, 4711);
# pack little-endian 16- and 32-bit signed integers
#print "$foo\n";
assert(join(',', unpack('s<l<', $foo)) eq '-42,4711');
#$foo = pack('(sl)<', -42, 4711);
# exactly the same
#print "$foo\n";

# This case will be split up into 2 parts to be handled by struct
$foo = pack('N!l<', -42, 4711);
assert(join(',', unpack('N!l<', $foo)) eq '-42,4711');


# Try some floating point and whitespace in the formats
$foo = pack(' f ', -3.5);
@arr = unpack(' f ', $foo);
assert(@arr == 1 && $arr[0] == -3.5);

$foo = pack(' d d ', 2.5, 100.0);
@arr = unpack(' d d ', $foo);
assert(@arr == 2 && $arr[0] == 2.5 && $arr[1] == 100.0);

print "$0 - test passed!\n";
