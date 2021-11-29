# Escaped interpolation symbols in "..." generate incorrect code
use Carp::Assert;

$s1 = "\@notarr\$notscalar\"notquote\\";
assert($s1 eq '@notarr$notscalar"notquote\\');
$i = 1;
$s2 = "{bracketed}$i";
assert($s2 eq '{bracketed}1');
$s3 = q(@notarr$notscalar\backsl'squote"dquote\)isCloseIsBackslash\\);
assert($s3 eq '@notarr$notscalar\backsl\'squote"dquote)isCloseIsBackslash\\');
assert(substr($s3,-1,1) eq "\\");
$s4 = '\n\r\a\b\c\d\e\\';
assert($s4 eq q(\n\r\a\b\c\d\e\\));
assert(substr($s4,0,1) eq "\\");
assert(substr($s4,1,1) eq "n");
$s4 =~ s/\\//g;
assert($s4 eq 'nrabcde');
assert($s4 =~ /\b\w+\b/);
print "$0 - test passed!\n";
