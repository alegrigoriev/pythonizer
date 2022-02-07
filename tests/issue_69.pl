# issue 69 - Pythonizer can't handle whitespace after q, qq, qw, etc

use Carp::Assert;

$a = q  /abc/;
$b = qq  /$a/;
@c = qw /a b c/;

assert($a eq 'abc');
assert($b eq 'abc');
assert(join('', @c) eq 'abc');

print "$0 - test passed!\n";
