# issue 106: String as regex

use Carp::Assert;

$browser = "IE version 2";
assert($browser =~ "IE");

$ie = "IE";
assert($browser =~ $ie);

@arie = ('', 'IE');
assert($browser =~ $arie[1]);

assert(lc($browser) =~ lc($ie));

assert($browser =~ "IE" && lc($browser) =~ lc($ie));

print "$0 - test passed!\n";
