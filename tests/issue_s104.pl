# issue s104: Don't assume the default variable is a string
use Carp::Assert;

undef $_;
assert(!defined);
chomp;
assert($_ eq '');
undef $_;
chop;
assert($_ eq '');
$_ = 123;
chomp;
assert($_ == 123);
$_ = 123;
chop;
assert($_ == 12);
undef $_;
print;
print STDERR;
printf;
printf STDOUT;
assert(reverse == '');

print "$0 - test passed!\n";
