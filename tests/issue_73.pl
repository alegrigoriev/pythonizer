# issue 73 - no code is generated for pattern match in spite of side effects
use Carp::Assert;
$abc = "abc";
$abc =~ s/abc/cba/;
assert($abc eq 'cba');

"abc" =~ /(abc)/;
assert($1 eq 'abc');

$abc =~ /(cba)/;
assert($1 eq 'cba');
print "$0 - test passed!\n";
