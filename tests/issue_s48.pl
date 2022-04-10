# When an array or hash is passed to a function that expects a number, the length needs to be passed instead
use Carp::Assert;

my @t = qw/a b c/;
my @d = qw/e f/;
my $result = join( '/', splice @t, 0, +@d );
assert($result eq 'a/b');
$result = join( '/', splice @t, 0, @d );
assert($result eq 'c');
@t = qw/a b c/;
$result = join( '/', splice @t, 0, @d );
assert($result eq 'a/b');

print "$0 - test passed!\n";
