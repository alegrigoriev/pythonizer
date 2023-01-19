# Test for HTML::Entities, written by chatGPT
use utf8;
#use lib "..";
use HTML::Entities;
use Carp::Assert;

# Test encoding an ASCII string
my $ascii_string = 'This is an ASCII string';
my $expected_encoded_string = 'This is an ASCII string';
my $encoded_string = encode_entities($ascii_string);
assert($encoded_string eq $expected_encoded_string, "Failed to encode ASCII string: $encoded_string vs $expected_encoded_string");

# Test encoding a non-ASCII string
my $non_ascii_string = 'Thìs ìs a nön-ÄSCIÎ strïng';
#my $expected_encoded_string = 'Th&igrave;s &igrave;s a n&ouml;n-&Auml;SCI&Igrave; str&iuml;ng';
my $expected_encoded_string = 'Th&igrave;s &igrave;s a n&ouml;n-&Auml;SCI&Icirc; str&iuml;ng';
$encoded_string = encode_entities($non_ascii_string);
assert($encoded_string eq $expected_encoded_string, "Failed to encode non-ASCII string $encoded_string vs $expected_encoded_string");

# Test decoding an encoded string
my $decoded_string = decode_entities($encoded_string);
assert($decoded_string eq $non_ascii_string, "Failed to decode encoded string: $decoded_string vs $non_ascii_string");

# Test encoding a string with all ASCII characters
my $all_ascii_chars = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
#my $expected_encoded_string = '!&quot;#$%&amp;&apos;()*+,-./0123456789:;&lt;=&gt;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
my $expected_encoded_string = '!&quot;#$%&amp;&#39;()*+,-./0123456789:;&lt;=&gt;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
$encoded_string = encode_entities($all_ascii_chars);
assert($encoded_string eq $expected_encoded_string, "Failed to encode string with all ASCII characters $encoded_string vs $expected_encoded_string");

# Test decoding a string with all encoded ASCII characters
$decoded_string = decode_entities($expected_encoded_string);
assert($decoded_string eq $all_ascii_chars, "Failed to decode string with all encoded ASCII characters: $decoded_string vs $all_ascii_chars");

# Test encoding an ASCII string with a specified encoding
my $ascii_string = 'This is an ASCII string.';
my $expected_encoded_string = 'This is an ASCII string&#46;';
my $encoded_string = encode_entities($ascii_string, '.');
assert($encoded_string eq $expected_encoded_string, "Failed to encode ASCII string with specified encoding: $encoded_string vs $expected_encoded_string");

# Test encoding a non-ASCII string with a specified encoding
my $non_ascii_string = 'Thìs ìs a nön-ÄSCIÎ strïng';
my $expected_encoded_string = 'Th&igrave;s &igrave;s a n&ouml;n-&Auml;SCI&Icirc; str&iuml;ng';
$encoded_string = encode_entities($non_ascii_string, '^\x00-\x7F');
assert($encoded_string eq $expected_encoded_string, "Failed to encode non-ASCII string with specified encoding: $encoded_string vs $expected_encoded_string");

# Test encoding a string with all ASCII characters with a specified encoding
my $all_ascii_chars = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
my $expected_encoded_string = '&#33;&quot;&#35;&#36;&#37;&amp;&#39;&#40;&#41;&#42;&#43;&#44;&#45;&#46;&#47;&#48;&#49;&#50;&#51;&#52;&#53;&#54;&#55;&#56;&#57;&#58;&#59;&lt;&#61;&gt;&#63;&#64;&#65;&#66;&#67;&#68;&#69;&#70;&#71;&#72;&#73;&#74;&#75;&#76;&#77;&#78;&#79;&#80;&#81;&#82;&#83;&#84;&#85;&#86;&#87;&#88;&#89;&#90;&#91;\&#93;&#94;&#95;&#96;abcdefghijklmnopqrstuvwxyz{|}~';
$encoded_string = encode_entities($all_ascii_chars, '!"#\$%&\'()*+,-./0123456789:;<=>?\@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`');
assert($encoded_string eq $expected_encoded_string, "Failed to encode string with all ASCII characters with specified encoding: $encoded_string vs $expected_encoded_string");


use HTML::Entities 'encode_entities_numeric';

# Test encoding an ASCII string
my $ascii_string = 'This is an ASCII string';
my $expected_encoded_string = 'This is an ASCII string';
my $encoded_string = encode_entities_numeric($ascii_string);
assert($encoded_string eq $expected_encoded_string, "Failed to encode ASCII string: $encoded_string vs $expected_encoded_string");

# Test encoding a non-ASCII string
my $non_ascii_string = 'Thìs ìs a nön-ÄSCIÎ strïng';
#my $expected_encoded_string = 'Th&#236;s &#236;s a n&#246;n-&#196;SCI&#206; str&#239;ng';
my $expected_encoded_string = 'Th&#xEC;s &#xEC;s a n&#xF6;n-&#xC4;SCI&#xCE; str&#xEF;ng';
$encoded_string = encode_entities_numeric($non_ascii_string);
assert($encoded_string eq $expected_encoded_string, "Failed to encode numeric non-ASCII string $encoded_string vs $expected_encoded_string");

# Test encoding a string with all ASCII characters
my $all_ascii_chars = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
#my $expected_encoded_string = '!&quot;#$%&amp;&apos;()*+,-./0123456789:;&lt;=&gt;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
my $expected_encoded_string = '!&#x22;#$%&#x26;&#x27;()*+,-./0123456789:;&#x3C;=&#x3E;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
$encoded_string = encode_entities_numeric($all_ascii_chars);
assert($encoded_string eq $expected_encoded_string, "Failed to encode numeric string with all ASCII characters $encoded_string vs $expected_encoded_string");

# Test encoding an ASCII string with a specified encoding
my $ascii_string = 'This is an ASCII string>';
my $expected_encoded_string = 'This is an ASCII string&#x3E;';
my $encoded_string = encode_entities_numeric($ascii_string, '>');
assert($encoded_string eq $expected_encoded_string, "Failed to encode ASCII string with specified encoding: $encoded_string vs $expected_encoded_string");

# Test encoding a non-ASCII string with a specified encoding
my $non_ascii_string = 'Thìs ìs a nön-ÄSCIÎ strïng';
my $expected_encoded_string = 'Th&#xEC;s &#xEC;s a n&#xF6;n-&#xC4;SCI&#xCE; str&#xEF;ng';
$encoded_string = encode_entities_numeric($non_ascii_string, '^\x00-\x7F');
assert($encoded_string eq $expected_encoded_string, "Failed to encode non-ASCII string with specified encoding: $encoded_string vs $expected_encoded_string");

# Test encoding a string with all ASCII characters with a specified encoding
my $all_ascii_chars = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
my $expected_encoded_string = '&#x21;&#x22;&#x23;&#x24;&#x25;&#x26;&#x27;&#x28;&#x29;&#x2A;&#x2B;&#x2C;&#x2D;&#x2E;&#x2F;&#x30;&#x31;&#x32;&#x33;&#x34;&#x35;&#x36;&#x37;&#x38;&#x39;&#x3A;&#x3B;&#x3C;&#x3D;&#x3E;&#x3F;&#x40;&#x41;&#x42;&#x43;&#x44;&#x45;&#x46;&#x47;&#x48;&#x49;&#x4A;&#x4B;&#x4C;&#x4D;&#x4E;&#x4F;&#x50;&#x51;&#x52;&#x53;&#x54;&#x55;&#x56;&#x57;&#x58;&#x59;&#x5A;&#x5B;\&#x5D;&#x5E;&#x5F;&#x60;abcdefghijklmnopqrstuvwxyz{|}~';
$encoded_string = encode_entities_numeric($all_ascii_chars, '!"#\$%&\'()*+,-./0123456789:;<=>?\@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`');
assert($encoded_string eq $expected_encoded_string, "Failed to encode string with all ASCII characters with specified encoding: $encoded_string vs $expected_encoded_string");


# Test decoding an encoded ASCII string
my $encoded_ascii_string = 'This is an ASCII string';
my $expected_decoded_string = 'This is an ASCII string';
_decode_entities($encoded_ascii_string, \%HTML::Entities::entity2char);
$decoded_string = $encoded_ascii_string;
assert($decoded_string eq $expected_decoded_string, "Failed to decode encoded ASCII string: $decoded_string vs $expected_decoded_string");

# Test decoding an encoded non-ASCII string
my $encoded_non_ascii_string = 'Th&igrave;s &igrave;s a n&ouml;n-&Auml;SCI&Icirc; str&iuml;ng';
my $expected_decoded_string = 'Thìs ìs a nön-ÄSCIÎ strïng';
_decode_entities($encoded_non_ascii_string, \%HTML::Entities::entity2char);
$decoded_string = $encoded_non_ascii_string;
assert($decoded_string eq $expected_decoded_string, "Failed to decode encoded non-ASCII string: $decoded_string vs $expected_decoded_string");

# Test decoding an encoded string with all ASCII characters
my $encoded_all_ascii_chars = '!&quot;#$%&amp;&apos;()*+,-./0123456789:;&lt;=&gt;?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
my $expected_decoded_string = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~';
_decode_entities($encoded_all_ascii_chars, \%HTML::Entities::entity2char);
$decoded_string = $encoded_all_ascii_chars;
assert($decoded_string eq $expected_decoded_string, "Failed to decode encoded string with all ASCII characters: $decoded_string vs $expected_decoded_string");

print "$0 - test passed!\n";

