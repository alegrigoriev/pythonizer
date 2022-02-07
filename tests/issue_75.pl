# issue 75 - Incorrect code for pattern matches

use Carp::Assert;

#Perl pattern matches generate calls to re.match(). The correct semantics for patterns that are not anchored is re.search().

my $string = "abcdef";
assert($string =~ /cde/);
assert($-[0] == 2);
assert($+[0] == 5);

print "$0 - test passed!\n";
