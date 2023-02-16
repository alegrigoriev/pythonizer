# -*- coding: utf-8 -*-
# Test of Encode.pm, written by chatGPT & SNOOPYJC
# This test_Encode2 version imports the encode, decode, and is_utf8 methods to
# make sure we get our versions of them and not the versions defined by "use utf8"
use utf8;
use Encode qw/encode decode encode_utf8 decode_utf8 is_utf8/;
use Carp::Assert;
use Data::Dumper;

# Test the encode method
assert(encode('UTF-8', 'hello world') eq 'hello world');

# Test the decode method
assert(decode('UTF-8', 'hello world') eq 'hello world');

# Test the decode method with non-ASCII characters
assert(decode('UTF-8', "\xE3\x81\x93\xE3\x82\x93\xE3\x81\xAB\xE3\x81\xA1\xE3\x81\xAF\xE4\xB8\x96\xE7\x95\x8C") eq 'こんにちは世界');

sub print_it {                  # For debug only
    my $chars = shift;
    if(!defined $chars) {
        print "undef\n";
        return;
    } elsif(!$chars) {
        print '<empty string detected>';
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
assert(encode('shift_jis', 'こんにちは世界') eq "\x82\xb1\x82\xf1\x82\xc9\x82\xbf\x82\xcd\x90\xa2\x8a\x45");


# Test for an error condition
eval {
    # Code that is expected to throw an error
    decode('UTF-8', "\xC3\x28", Encode::FB_CROAK|Encode::LEAVE_SRC);
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

  # Encode the string in ASCII and return the result
  return encode('ASCII', $string);
}

# Test function
sub test_encoding {
  # Test the subroutine with a UTF-8 encoded string
  assert(check_encoding("\x{263a}") eq "?", "Unexpected output for input ('\x{263a}')");

  # Test the subroutine with a non-UTF-8 encoded string
  assert(check_encoding(pack('C*', 0xC2, 0xA9)) =~ /\?/, "Unexpected output for input (pack('C*', 0xC2, 0xA9))");
}

# Run the test
test_encoding();

# Test `decode_utf8`
assert(decode_utf8("\xC3\xA9") eq "\x{00E9}", "Unexpected output for input ('\xC3\xA9') with decode_utf8");

# Test `encode_utf8`
assert(encode_utf8("\x{00E9}") eq "\xC3\xA9", "Unexpected output for input ('\x{00E9}') with encode_utf8");

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
assert($utf8_encoding->encode("\x{00E9}") eq "\xC3\xA9", "Unexpected output for input ('\x{00E9}') with \$obj->encode");
assert($utf8_encoding->decode("\xC3\xA9") eq "\x{00E9}", "Unexpected output for input ('\xC3\xA9') with \$obj->decode");

# Test `find_mime_encoding`
my $iso8859_1_encoding = Encode::find_mime_encoding('ISO-8859-1');
assert(defined $iso8859_1_encoding, "Unexpected output for input ('ISO-8859-1') with find_mime_encoding");

# Test `clone_encoding`
my $utf8_encoding_clone = Encode::clone_encoding('UTF-8');
assert(defined $utf8_encoding_clone, "Unexpected output for input (\$utf8_encoding) with clone_encoding");

sub check_encoding2 {
  my ($string, $flag) = @_;

  my $decoded_string;

  eval {
    # Decode the string using the specified flag
    $decoded_string = decode('UTF-8', $string, $flag|Encode::LEAVE_SRC);
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
  assert($line =~ /does not map/ || $line =~ /codec can't decode byte 0xc3/);
}

END {
    unlink "tmp.tmp";
}

# Run the test
test_encoding2();

sub error_handler {
    my ($chr) = @_;
    return sprintf "\\x{%02x}", $chr;
}

sub test_sub_error_handler {
    my $input = "a\x{F1}b";
    my $expected_output = "a\\x{f1}b";
    my $output = decode("UTF-8", $input, \&error_handler);
    assert($output eq $expected_output, "Test sub: Unexpected output from decode: $output");

    $input = "a\x{F1}b";
    $expected_output = "a\\x{f1}b";
    $output = encode("ascii", $input, \&error_handler);
    assert($output eq $expected_output, "Test sub: Unexpected output from encode: $output");
}

test_sub_error_handler();

sub test_partial_buffer_with_restart {
    my $partial_input = "a\xC3";
    my $output = decode('utf8', $partial_input, Encode::FB_QUIET);
    assert($output eq "a", "Unexpected output from partial input: $partial_input");

    my $complete_input = $partial_input . "\xA9";
    $output .= decode('utf8', $complete_input, Encode::FB_QUIET);
    assert($output eq "a\x{e9}", "Unexpected output from complete input: $complete_input");

    # Ensure that the decoder can be used again after a successful decode
    $output = decode('utf8', "\xC3\xA9");
    assert($output eq "\x{e9}", "Unexpected output from second decode: $output");

    # Now try something a little more complex:

    for(my $length = 2; $length <= 100; $length += 2) {
        my $full_input = "\xC3\xA9" x ($length/2);
        for(my $at_a_time = 1; $at_a_time <= 50; $at_a_time++) {
            #my @pieces = unpack "(A$at_a_time)*", $full_input;
            my @pieces;
            for(my $i = 0; $i < $length; $i+=$at_a_time) {
                push @pieces, substr($full_input, $i, $at_a_time);
            }
            #print "for length $length and $at_a_time, got " . scalar(@pieces) . " pieces\n";
            $partial_input = '';
            $output = '';
            for(my $i = 0; $i < scalar(@pieces); $i++) {
                $partial_input .= $pieces[$i];
                $output .= decode('utf8', $partial_input, Encode::FB_QUIET);
            }
            my $expected_output = "\x{e9}" x ($length/2);
            if($output ne $expected_output) {
                print "length = $length, at_a_time = $at_a_time\n";
                print "Output          = "; print_it($output);
                print "Expected Output = "; print_it($expected_output);
            }
            assert($output eq $expected_output);
            my $a = 'a';
            decode('utf8', $a, Encode::FB_QUIET);        # Clear the decoder
        }
    }

    # See if we can abandon a partial translation and send in a new one (that's different)
    $partial_input = "b\xC3";
    $output = decode('utf8', $partial_input, Encode::FB_QUIET);
    assert($output eq "b", "Unexpected output from partial input: $partial_input");
    
    # Ensure that the decoder can be used again after a incomplete decode
    $partial_input = "\xC3\xA9";
    $output = decode('utf8', $partial_input, Encode::FB_QUIET);
    assert($output eq "\x{e9}", "Unexpected output from decode after incomplete decode: $output");
}

sub test_partial_buffer_with_restart_utf8 {
    my $partial_input = "a\xC3";
    my $output = decode_utf8($partial_input, Encode::FB_QUIET);
    assert($output eq "a", "Unexpected output from partial input: $partial_input");

    my $complete_input = $partial_input . "\xA9";
    $output .= decode_utf8($complete_input, Encode::FB_QUIET);
    assert($output eq "a\x{e9}", "Unexpected output from complete input: $complete_input");

    # Ensure that the decode_utf8r can be used again after a successful decode_utf8
    $output = decode_utf8("\xC3\xA9");
    assert($output eq "\x{e9}", "Unexpected output from second decode_utf8: $output");

    # Now try something a little more complex:

    for(my $length = 2; $length <= 100; $length += 2) {
        my $full_input = "\xC3\xA9" x ($length/2);
        for(my $at_a_time = 1; $at_a_time <= 50; $at_a_time++) {
            #my @pieces = unpack "(A$at_a_time)*", $full_input;
            my @pieces;
            for(my $i = 0; $i < $length; $i+=$at_a_time) {
                push @pieces, substr($full_input, $i, $at_a_time);
            }
            #print "for length $length and $at_a_time, got " . scalar(@pieces) . " pieces\n";
            $partial_input = '';
            $output = '';
            for(my $i = 0; $i < scalar(@pieces); $i++) {
                $partial_input .= $pieces[$i];
                $output .= decode_utf8($partial_input, Encode::FB_QUIET);
            }
            my $expected_output = "\x{e9}" x ($length/2);
            if($output ne $expected_output) {
                print "length = $length, at_a_time = $at_a_time\n";
                print "Output          = "; print_it($output);
                print "Expected Output = "; print_it($expected_output);
            }
            assert($output eq $expected_output);
            my $a = 'a';
            decode_utf8($a, Encode::FB_QUIET);        # Clear the decode_utf8r
        }
    }

    # See if we can abandon a partial translation and send in a new one (that's different)
    $partial_input = "b\xC3";
    $output = decode_utf8($partial_input, Encode::FB_QUIET);
    assert($output eq "b", "Unexpected output from partial input: $partial_input");
    
    # Ensure that the decoder can be used again after a incomplete decode_utf8
    $partial_input = "\xC3\xA9";
    $output = decode_utf8($partial_input, Encode::FB_QUIET);
    assert($output eq "\x{e9}", "Unexpected output from decode_utf8 after incomplete decode_utf8: $output");
}

sub test_partial_buffer_with_restart_obj {
    my $obj = Encode::find_encoding("UTF-8");
    my $partial_input = "a\xC3";
    my $output = $obj->decode($partial_input, Encode::FB_QUIET);
    assert($output eq "a", "Unexpected output from partial input: $partial_input");

    my $complete_input = $partial_input . "\xA9";
    $output .= $obj->decode($complete_input, Encode::FB_QUIET);
    assert($output eq "a\x{e9}", "Unexpected output from complete input: $complete_input");

    # Ensure that the decoder can be used again after a successful decode
    $output = $obj->decode("\xC3\xA9");
    assert($output eq "\x{e9}", "Unexpected output from second decode: $output");

    # Now try something a little more complex:

    for(my $length = 2; $length <= 100; $length += 2) {
        my $full_input = "\xC3\xA9" x ($length/2);
        for(my $at_a_time = 1; $at_a_time <= 50; $at_a_time++) {
            #my @pieces = unpack "(A$at_a_time)*", $full_input;
            my @pieces;
            for(my $i = 0; $i < $length; $i+=$at_a_time) {
                push @pieces, substr($full_input, $i, $at_a_time);
            }
            #print "for length $length and $at_a_time, got " . scalar(@pieces) . " pieces\n";
            $partial_input = '';
            $output = '';
            for(my $i = 0; $i < scalar(@pieces); $i++) {
                $partial_input .= $pieces[$i];
                $output .= $obj->decode($partial_input, Encode::FB_QUIET);
            }
            my $expected_output = "\x{e9}" x ($length/2);
            if($output ne $expected_output) {
                print "length = $length, at_a_time = $at_a_time\n";
                print "Output          = "; print_it($output);
                print "Expected Output = "; print_it($expected_output);
            }
            assert($output eq $expected_output);
            my $a = 'a';
            $obj->decode($a, Encode::FB_QUIET);        # Clear the decoder
        }
    }

    # See if we can abandon a partial translation and send in a new one (that's different)
    $partial_input = "b\xC3";
    $output = $obj->decode($partial_input, Encode::FB_QUIET);
    assert($output eq "b", "Unexpected output from partial input: $partial_input");
    
    # Ensure that the decoder can be used again after a incomplete decode
    $partial_input = "\xC3\xA9";
    $output = $obj->decode($partial_input, Encode::FB_QUIET);
    assert($output eq "\x{e9}", "Unexpected output from decode after incomplete decode: $output");
}

test_partial_buffer_with_restart();
test_partial_buffer_with_restart_utf8();
test_partial_buffer_with_restart_obj();

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

# Test Encode::is_utf8
sub test_is_utf8 {
  # Test a string encoded in UTF-8
  my $input = "\x{263a}";
  my $output = is_utf8($input);
  assert($output, "Unexpected output: $output");

  # Test a string encoded in ISO-8859-1
  #$input = "\x{00E9}";
  $input = "A";
  $output = is_utf8($input);
  assert(!$output, "Unexpected output: $output");
}
test_is_utf8();

# Test for define_encoding
package Encode::MyEncoding;
use Carp::Assert;
use Encode;
use parent qw(Encode::Encoding);
__PACKAGE__->Define(qw(TestEncoding));
sub encode($$;$){
    my ($obj, $str, $chk) = @_;
    $str =~ tr/A-Za-z/N-ZA-Mn-za-m/;
    #$_[1] = '' if $chk; # this is what in-place edit means
    return $str;
}
*decode = \&Encode::MyEncoding::encode;

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
  my $actual_output = encode("TestEncoding", $input);
  assert($actual_output eq $expected_output, "Unexpected output from encode ('$actual_output' != '$expected_output')");

  # Test decoding with the newly defined encoding
  $input = $expected_output;
  $expected_output = "Test";
  $actual_output = decode("TestEncoding", $input);
  assert($actual_output eq $expected_output, "Unexpected output from decode ('$actual_output' != '$expected_output')");
}
test_define_encoding();

sub test_define_alias {
    Encode::define_alias("newalias" => "UTF-8");
    my $utf8_encoder = Encode::find_encoding("UTF-8");
    my $newalias_encoder = Encode::find_encoding("newalias");

    my $input = "abcdé";
    my $utf8_encoded = $utf8_encoder->encode($input);
    my $newalias_encoded = $newalias_encoder->encode($input);
    assert($utf8_encoded eq $newalias_encoded, "Unexpected encoding result from new alias");

    my $utf8_decoded = $utf8_encoder->decode($utf8_encoded);
    my $newalias_decoded = $newalias_encoder->decode($newalias_encoded);
    assert($utf8_decoded eq $newalias_decoded, "Unexpected decoding result from new alias");
}

test_define_alias();



# Test for from_to
sub test_from_to2 {
  my $ascii_string = "Hello World";
  my $utf8_string = encode("UTF-8", $ascii_string);
  my $length = Encode::from_to($utf8_string, "UTF-8", "ASCII");
  assert($utf8_string eq $ascii_string, "Converted string '$utf8_string' does not match expected output '$ascii_string'");
  assert($length == 11);
}
test_from_to2();

sub test_perlio_ok {
  # Test perlio_ok for an encoding that is compatible with PerlIO
  assert(Encode::perlio_ok("UTF-8"), "perlio_ok failed for encoding 'UTF-8'");
  assert(Encode::perlio_ok("Shift_JIS"), "perlio_ok failed for encoding 'Shift_JIS'");

  # Test perlio_ok for an encoding that is not compatible with PerlIO
  # Python supports this encoding on I/O
  #assert(!Encode::perlio_ok("ISO-2022-kr"), "perlio_ok failed for encoding 'ISO-2022-kr'");
}
test_perlio_ok();

sub test_resolve_alias {
  # Test resolve_alias for a well-known encoding
  $result = Encode::resolve_alias("UTF-8");
  assert($result eq "utf-8" || $result eq "utf-8-strict", "resolve_alias failed for encoding 'utf-8'");

  # Test resolve_alias for an unknown encoding
  assert(!Encode::resolve_alias("unknown"), "resolve_alias failed for encoding 'unknown'");
}
test_resolve_alias();

print "$0 - test passed!\n";
