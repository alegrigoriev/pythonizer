# issue 83 - Quoted strings with nested brackets don't find the end properly
use Carp::Assert;

# Quoted strings with nested brackets don't find the end properly: "If the delimiters are bracketing, nested pairs are also skipped. For example, while searching for a closing ] paired with the opening [, combinations of \, ], and [ are all skipped, and nested [ and ] are skipped as well." For example:


my $string = q{...{...}...};
assert($string eq '...{...}...');
$string = q[...[...]...];
assert($string eq '...[...]...');
$string = q(...(...)...);
assert($string eq '...(...)...');
$string = q[...(...)...];
assert($string eq '...(...)...');
$string = q{...(...)...};
assert($string eq '...(...)...');
$string = q'...(...)...';
assert($string eq '...(...)...');
$string = q/...(...).../;
assert($string eq '...(...)...');

print "$0 - test passed!\n";
