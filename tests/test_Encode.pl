# -*- coding: utf-8 -*-
# Test of Encode.pm, written by chatGPT
# pragma pythonizer -s
use utf8;
use Encode;
use Carp::Assert;

# Test the encode method
assert(Encode::encode('UTF-8', 'hello world') eq 'hello world');

# Test the decode method
assert(Encode::decode('UTF-8', 'hello world') eq 'hello world');

# Test the decode method with non-ASCII characters
assert(Encode::decode('UTF-8', "\xE3\x81\x93\xE3\x82\x93\xE3\x81\xAB\xE3\x81\xA1\xE3\x81\xAF\xE4\xB8\x96\xE7\x95\x8C") eq 'こんにちは世界');

sub print_it {                  # For debug only
    my $chars = shift;
    if(!defined $chars) {
        print "undef\n";
        return;
    }
    for(my $i = 0; $i < length($chars); $i++) {
        my $c = ord(substr($chars, $i, 1));
        if($c < 256) {
            printf "\\x%02x", $c;
        } elsif($c < 65536) {
            printf "\\x{%04x}", $c;
        } else {
            printf "\\x{%06x}", $c;
        }
    }
    print "\n";
}

# Test the encode method with non-ASCII characters and a different encoding type
assert(Encode::encode('shift_jis', 'こんにちは世界') eq "\x82\xb1\x82\xf1\x82\xc9\x82\xbf\x82\xcd\x90\xa2\x8a\x45");


# Test for an error condition
eval {
    # Code that is expected to throw an error
    Encode::decode('UTF-8', "\xC3\x28", Encode::FB_CROAK);
};
if ($@) {
    # If an error was thrown, the test case passes
    assert(1);
} else {
    # If no error was thrown, the test case fails
    assert(0);
}

# Subroutine being tested
sub check_encoding {
  my ($string) = @_;

  # Check that the input string is encoded in UTF-8
  assert(utf8::is_utf8($string), "Input string is not encoded in UTF-8: $string");

  # Encode the string in ASCII and return the result
  return Encode::encode('ASCII', $string);
}

# Test function
sub test_encoding {
  # Test the subroutine with a UTF-8 encoded string
  assert(check_encoding("\x{263a}") eq "?", "Unexpected output for input ('\x{263a}')");

  # Test the subroutine with a non-UTF-8 encoded string
  eval { check_encoding(pack('C*', 0xC2, 0xA9)) };
  assert($@ =~ /Input string is not encoded in UTF-8/, "Unexpected output for input (pack('C*', 0xC2, 0xA9))");
}

# Run the test
test_encoding();

# Test `decode_utf8`
assert(Encode::decode_utf8("\xC3\xA9") eq "\x{00E9}", "Unexpected output for input ('\xC3\xA9') with decode_utf8");

# Test `encode_utf8`
assert(Encode::encode_utf8("\x{00E9}") eq "\xC3\xA9", "Unexpected output for input ('\x{00E9}') with encode_utf8");

# Test `str2bytes`
assert(Encode::str2bytes("UTF-8", "\x{00E9}") eq "\xC3\xA9", "Unexpected output for input ('\x{00E9}') with str2bytes");

# Test `bytes2str`
assert(Encode::bytes2str("UTF-8", "\xC3\xA9") eq "\x{00E9}", "Unexpected output for input ('\xC3\xA9') with bytes2str");
assert(Encode::bytes2str("UTF-8", "\xC3\x28") eq "\x{FFFD}\x28", "Unexpected output for input ('\xC3\x28') with bytes2str");

# Test `encodings`
my @encodings = Encode::encodings();
assert(scalar @encodings > 0, "Unexpected output for encodings");

# Test `find_encoding`
my $utf8_encoding = Encode::find_encoding('UTF-8');
assert(defined $utf8_encoding, "Unexpected output for input ('UTF-8') with find_encoding");

# Test `find_mime_encoding`
my $iso8859_1_encoding = Encode::find_mime_encoding('ISO-8859-1');
assert(defined $iso8859_1_encoding, "Unexpected output for input ('ISO-8859-1') with find_mime_encoding");

# Test `clone_encoding`
my $utf8_encoding_clone = Encode::clone_encoding($utf8_encoding);
assert(defined $utf8_encoding_clone, "Unexpected output for input (\$utf8_encoding) with clone_encoding");

use Encode;
use Carp::Assert;

# Subroutine being tested
sub check_encoding2 {
  my ($string, $flag) = @_;

  my $decoded_string;

  eval {
    # Decode the string using the specified flag
    $decoded_string = Encode::decode('UTF-8', $string, $flag);
  };

  # Check the behavior based on the specified flag
  if ($flag == Encode::FB_CROAK) {
    assert($@, "Expected exception not thrown for FB_CROAK");
  } elsif ($flag == Encode::FB_QUIET) {
    assert(!$decoded_string, "Expected '' for FB_QUIET");
  } elsif ($flag == Encode::FB_WARN) {
    assert(!$@, "Unexpected exception thrown for FB_WARN");
  }

  return $decoded_string;
}

# Test function
sub test_encoding2 {
  # Test the subroutine with Encode::FB_CROAK
  #eval { check_encoding2("\xC3\x28", Encode::FB_CROAK) };
  #assert($@, "Expected exception not thrown for FB_CROAK");
  check_encoding2("\xC3\x28", Encode::FB_CROAK);

  # Test the subroutine with Encode::FB_QUIET
  check_encoding2("\xC3\x28", Encode::FB_QUIET);

  # Test the subroutine with Encode::FB_WARN
  open OLD_STDERR, ">&", STDERR;
  close(STDERR);
  open(STDERR, '>tmp.tmp');
  check_encoding2("\xC3\x28", Encode::FB_WARN);
  close(STDERR);
  open STDERR, ">&", OLD_STDERR;
  open(TMP, '<tmp.tmp');
  my $line = <TMP>;
  close(TMP);
  assert($line =~ "does not map");
}

END {
    unlink "tmp.tmp";
}

# Run the test
test_encoding2();

use Encode qw/define_encoding from_to is_utf8 perlio_ok resolve_alias/;

# Test Encode::from_to
sub test_from_to {
  # Test conversion from UTF-8 to ASCII
  my $input = "\x{263a}";
  eval {my $output = Encode::from_to($input, "UTF-8", "ASCII");};
  #assert($output eq "?", "Unexpected output: $output");
  assert($@, "from_to: expected error not present!");

  # Test conversion from ISO-8859-1 to UTF-8
  $input = "\x{00E9}";
  my $length = Encode::from_to($input, "ISO-8859-1", "UTF-8");
  assert($input eq "\x{00C3}\x{00A9}", "Unexpected output: $input");
  assert($length eq '2', "Unexpected output: $output");
}
test_from_to();

# Test Encode::is_16bit
sub test_is_16bit {
  # Test a string encoded in UTF-8
  my $input = "\x{263a}";
  my $output = Encode::is_16bit($input);
  assert(!$output, "Unexpected output: $output");

  # Test a string encoded in UTF-16
  $input = "\x{263a}\x{263a}";
  $output = Encode::is_16bit($input);
  assert($output, "Unexpected output: $output");
}
# is_16bit doesn't exist!!  test_is_16bit();

# Test Encode::is_8bit
sub test_is_8bit {
  # Test a string encoded in UTF-8
  my $input = "\x{263a}";
  my $output = Encode::is_8bit($input);
  assert(!$output, "Unexpected output: $output");

  # Test a string encoded in ISO-8859-1
  $input = "\x{00E9}";
  $output = Encode::is_8bit($input);
  assert($output, "Unexpected output: $output");
}
# is_8bit doesn't exist!!   test_is_8bit();

# Test Encode::is_utf8
sub test_is_utf8 {
  # Test a string encoded in UTF-8
  my $input = "\x{263a}";
  my $output = Encode::is_utf8($input);
  assert($output, "Unexpected output: $output");

  # Test a string encoded in ISO-8859-1
  $input = "\x{00E9}";
  $output = Encode::is_utf8($input);
  assert(!$output, "Unexpected output: $output");
}
test_is_utf8();

# Test for utf8_upgrade
sub test_utf8_upgrade {
  # Test input string with ASCII characters
  my $ascii_string = "Hello World";
  my $utf8_string = Encode::utf8_upgrade($ascii_string);
  assert(Encode::is_utf8($utf8_string), "ASCII string not upgraded to UTF-8");

  # Test input string with UTF-8 characters
  $ascii_string = "\x{263a}";
  $utf8_string = Encode::utf8_upgrade($ascii_string);
  assert(Encode::is_utf8($utf8_string), "UTF-8 string not upgraded to UTF-8");
}
# utf8_upgrade doesn't exist!! test_utf8_upgrade();

# Test for utf8_downgrade
sub test_utf8_downgrade {
  # Test input string with ASCII characters
  my $ascii_string = "Hello World";
  my $utf8_string = Encode::utf8_upgrade($ascii_string);
  my $downgraded_string = Encode::utf8_downgrade($utf8_string);
  assert(!Encode::is_utf8($downgraded_string), "ASCII string not downgraded from UTF-8");

  # Test input string with UTF-8 characters
  $ascii_string = "\x{263a}";
  $utf8_string = Encode::utf8_upgrade($ascii_string);
  $downgraded_string = Encode::utf8_downgrade($utf8_string);
  assert(!Encode::is_utf8($downgraded_string), "UTF-8 string not downgraded from UTF-8");
}
# utf8_upgrade doesn't exist!!  test_utf8_downgrade();

# Test for define_encoding
package Encode::MyEncoding;
use Carp::Assert;
use Encode;
use parent qw(Encode::Encoding);
__PACKAGE__->Define(qw(TestEncoding));
sub encode($$;$){
    my ($obj, $str, $chk) = @_;
    $str =~ tr/A-Za-z/N-ZA-Mn-za-m/;
    $_[1] = '' if $chk; # this is what in-place edit means
    return $str;
}
*decode = \&encode;

package main;

sub test_define_encoding {
  # Define a new encoding
#  my $test_encoding = Encode::Encoding->new(
#    "TestEncoding",
#    Encode::FB_CROAK,
#    sub { "TestDecoded" },
#    sub { "TestEncoded" },
#  );
#  Encode::define_encoding($test_encoding, 'TestEncoding');

  # Test encoding with the newly defined encoding
  my $input = "Test";
  my $expected_output = "Grfg";
  my $actual_output = Encode::encode("TestEncoding", $input);
  assert($actual_output eq $expected_output, "Unexpected output from encode ('$actual_output' != '$expected_output')");

  # Test decoding with the newly defined encoding
  $input = $expected_output;
  $expected_output = "Test";
  $actual_output = Encode::decode("TestEncoding", $input);
  assert($actual_output eq $expected_output, "Unexpected output from decode ('$actual_output' != '$expected_output')");
}
test_define_encoding();


# Test for from_to
sub test_from_to2 {
  my $ascii_string = "Hello World";
  my $utf8_string = Encode::encode("UTF-8", $ascii_string);
  my $length = Encode::from_to($utf8_string, "UTF-8", "ASCII");
  assert($utf8_string eq $ascii_string, "Converted string '$utf8_string' does not match expected output '$ascii_string'");
  assert($length == 11);
}
test_from_to2();

sub test_is_utf82 {
  # Test is_utf8 with a UTF-8 encoded string
  assert(Encode::is_utf8("\x{263a}"), "is_utf8 failed for string '\x{263a}'");

  # Test is_utf8 with an ASCII encoded string
  assert(!Encode::is_utf8("A"), "is_utf8 incorrect for string 'A'");

  # Test is_utf8 with a non-UTF-8 encoded string
  assert(!Encode::is_utf8(pack('C*', 0xC2, 0xA9)), "is_utf8 failed for string (pack('C*', 0xC2, 0xA9))");
}
test_is_utf82();

sub test_perlio_ok {
  # Test perlio_ok for an encoding that is compatible with PerlIO
  assert(Encode::perlio_ok("UTF-8"), "perlio_ok failed for encoding 'UTF-8'");
  assert(Encode::perlio_ok("Shift_JIS"), "perlio_ok failed for encoding 'Shift_JIS'");

  # Test perlio_ok for an encoding that is not compatible with PerlIO
  assert(!Encode::perlio_ok("ISO-2022-kr"), "perlio_ok failed for encoding 'ISO-2022-kr'");
}
test_perlio_ok();

sub test_resolve_alias {
  # Test resolve_alias for a well-known encoding
  assert(Encode::resolve_alias("utf-8") eq "utf-8-strict", "resolve_alias failed for encoding 'utf-8'");

  # Test resolve_alias for an unknown encoding
  assert(!Encode::resolve_alias("unknown"), "resolve_alias failed for encoding 'unknown'");
}
test_resolve_alias();

print "$0 - test passed!\n";
