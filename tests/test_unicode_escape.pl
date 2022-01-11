# Test unicode escapes and v strings
#
use Carp::Assert;

my $str1 = "\x{1}\x{14}\x{12c}\x{fa0}";
my $str2 = v1.20.300.4000;
my $str3 = "\1\24\454\x{fa0}";
assert($str1 eq $str2);
assert($str1 eq $str3);
assert(v9786 eq "\x{263a}");
assert(v9786 eq "\x{0263a}");
assert(v9786 eq "\x{00263a}");
assert(v9786 eq "\x{000263a}");
assert(v9786 eq "\x{0000263a}");
assert(v102.111.111 eq 'foo');
assert(102.111.111 eq 'foo');
assert(v65 eq chr(65));
my %h = (v65=>65);
assert($h{v65} == 65);
assert($h{'v65'} == 65);
assert("\N{LATIN CAPITAL LETTER A}" eq 'A');
my $i = ~v0;    # Just make sure this compiles
#print "" . (~v0) . "\n";

print "$0 - test passed!\n";
