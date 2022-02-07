# issue 44: qw/strings/ are not translated
use Carp::Assert;

my @arr = qw/str1 str2 str3/;

assert(3 == @arr);
assert(join('', @arr) eq 'str1str2str3');

print "$0 - test passed!\n";
