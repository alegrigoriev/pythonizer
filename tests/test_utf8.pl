# -*- coding: latin-1 -*-
use Carp::Assert;
use v5.11;
no feature 'unicode_strings';

# Test utf8::upgrade
my $ascii_string = "Hello, world!\xdf";
assert(utf8::upgrade($ascii_string));
#print STDOUT ord(substr($ascii_string,-1,1)) . "\n";
assert($ascii_string eq ('Hello, world!' . chr(223)));
assert(utf8::is_utf8($ascii_string));

# Test utf8::downgrade
assert(utf8::downgrade($ascii_string));
assert($ascii_string eq ('Hello, world!' . chr(223)));

# Test utf8::encode
my $ascii_string = "Hello, world!";
utf8::encode($ascii_string);
assert(!utf8::is_utf8($ascii_string));
assert(utf8::valid($ascii_string));

my $non_ascii_string = "Hello, world!\xdf";
utf8::encode($non_ascii_string);
#print STDOUT ord(substr($non_ascii_string,-2,1)) . ",";
#print STDOUT ord(substr($non_ascii_string,-1,1)) . "\n";
assert(ord(substr($non_ascii_string,-2,1)) == 0xc3);
assert(ord(substr($non_ascii_string,-1,1)) == 0x9f);
#assert($non_ascii_string eq "Hello, world!\xc3\x9f");
assert(substr($non_ascii_string,0,13) eq "Hello, world!");
assert(!utf8::is_utf8($non_ascii_string));
assert(utf8::valid($non_ascii_string));

# Test utf8::decode
assert(utf8::decode($ascii_string));
assert(!utf8::is_utf8($ascii_string));

assert(utf8::decode($non_ascii_string));
assert($non_ascii_string eq "Hello, world!\xdf");
assert(utf8::is_utf8($non_ascii_string));

# Test utf8::native_to_unicode
my $code_point = 0x263A;  # Unicode smiley face character
my $unicode_point = utf8::native_to_unicode($code_point);
assert($unicode_point == 0x263a);

# Test utf8::unicode_to_native
$code_point = utf8::unicode_to_native(0x263a);
assert($code_point == 0x263A);

# Test utf8::is_utf8
my $utf8_string = "\x{263A}";  # Unicode smiley face character
$ascii_string = "Hello, world!";
my $invalid_utf8_string = "\xC0\x41"; # Invalid UTF-8 sequence
assert(utf8::is_utf8($utf8_string));
assert(!utf8::is_utf8($ascii_string));
assert(utf8::upgrade($invalid_utf8_string));
assert(utf8::is_utf8($invalid_utf8_string));

#assert(utf8::is_utf8("Hello, world!"));
assert(!utf8::is_utf8("\x{0041}\x{0042}\x{0043}"));

# Test utf8::valid
my $valid_utf8_string = "\x{263A}";  # Unicode smiley face character
assert(utf8::valid("Hello, world!"));
assert(utf8::valid($valid_utf8_string));
assert(utf8::valid($non_ascii_string));
assert(utf8::valid($invalid_utf8_string));  # valid doesn't really check if the string is valid

print "$0 - test passed\n";
