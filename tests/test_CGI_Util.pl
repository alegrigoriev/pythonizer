use CGI::Util qw/rearrange rearrange_header make_attributes unescape escape expires ebcdic2ascii ascii2ebcdic/;
use Carp::Assert;
#use Data::Dumper;

# Test rearrange
my @test_array = qw/a b c d/;
my %test_hash = (-a => 1, -b => 2, -c => 3, -d => 4);

my ($a, $b, $c, $d) = rearrange(\@test_array, %test_hash);
assert($a == 1);
assert($b == 2);
assert($c == 3);
assert($d == 4);
($b, $a, $d, $c) = rearrange([qw/b a d c/], %test_hash);
assert($a == 1);
assert($b == 2);
assert($c == 3);
assert($d == 4);


# Test rearrange_header
@test_array = qw/Content-Type Content-Length/;
my %header_hash = ('-Content-Type' => 'text/html; charset=utf-8', '-Content-Length' => 123);
@header_hash = rearrange_header(\@test_array, %header_hash);
assert($header_hash[0] eq 'text/html; charset=utf-8');
assert($header_hash[1] eq '123');

@test_array = qw/Content-Length Content-Type/;
@header_hash = rearrange_header(\@test_array, %header_hash);
assert($header_hash[0] eq '123');
assert($header_hash[1] eq 'text/html; charset=utf-8');

@test_array = qw/Content-Type/;
@header_hash = rearrange_header(\@test_array, %header_hash);
assert($header_hash[0] eq 'text/html; charset=utf-8');
assert($header_hash[1] eq 'content-length=123');

# Test make_attributes
my %attr_hash = (a => 1, b => 2, c => 3);
my @attr_string = make_attributes(\%attr_hash);
assert(join(' ', @attr_string) eq 'a="1" b="2" c="3"');

# Test unescape
my $escaped_string = 'This%20is%20an%20escaped%20string';
my $unescaped_string = unescape($escaped_string);
assert($unescaped_string eq 'This is an escaped string');

# Test escape
my $to_escape = 'This is a string to escape';
my $escaped = escape($to_escape);
assert($escaped eq 'This%20is%20a%20string%20to%20escape');

# Test expires
my $expires = expires(999986400, 'http');
assert($expires eq 'Sat, 08 Sep 2001 22:00:00 GMT');
$expires = expires(999986400, 'cookie');
assert($expires eq 'Sat, 08-Sep-2001 22:00:00 GMT');

# Test ebcdic2ascii
my $ebcdic_string = "\x81\x82\x83\x84";
my $ascii_string = ebcdic2ascii($ebcdic_string);
assert($ascii_string eq 'abcd');

# Test ascii2ebcdic
my $to_ebcdic = 'abcd';
my $ebcdic = ascii2ebcdic($to_ebcdic);
assert($ebcdic eq "\x81\x82\x83\x84");

print "$0 - test passed!\n";
