# In a regex, a [...] character class looks a lot like an array subscript
# Let's test a few cases to make sure the pythonizer can tell the difference

use Carp::Assert;

$_ = "abc";
$str = "abcd";

assert($str =~ /$_[d]/);
assert($str =~ /$_[a-z]/);
assert($str =~ /$_[^a]/);
assert($str =~ /$_[\w]/);
assert($str !~ /$_[^d]/);
@_ = ('abcd', 'defg');
assert($str =~ /$_[0]/);
assert($str !~ /$_[1]/);
$i = 0;
assert($str =~ /$_[$i]/);

sub def { 1 }
assert($str =~ /$_[def]/);	# No, that not a sub call!

print "$0 - test passed!\n";
