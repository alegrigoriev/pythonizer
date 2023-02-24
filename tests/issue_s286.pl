# issue s286 - Regex with M flag gives different results in perl vs python
use Carp::Assert;

my $string = "This is a test string\nwith multiple lines";

# Test matching a pattern at the beginning of a line
assert($string =~ /^This/m, "Match failed at the beginning of the line");
assert($string =~ /^with/m, "Match failed at the beginning of the line");

# Test matching a pattern at the end of a line
assert($string =~ /lines$/m, "Match failed at the end of the line");
assert($string =~ /string$/m, "Match failed at the end of the line");

# Test matching a pattern that spans multiple lines
assert($string =~ /^This.*lines$/ms, "Match failed across multiple lines");

# Test matching a pattern with optional characters
assert($string =~ /^This is a test( string)?/m, "Match failed with optional characters");
assert($string =~ /^This is a test( string)?$/m, "Match failed with optional characters");

# Test matching a pattern with character classes
assert($string =~ /^This[\w\s]+$/m, "Match failed with character classes");
assert($string =~ /^This[^0-9]+$/m, "Match failed with character classes");

# now some from perl5/t/re
assert("abcd\ndxxx" =~ /^d[x][x][x]/m, "Match failed on re test 1");
assert("a\n\n" =~ m'\Aa$'m, "Match failed on re test 2");
assert("a\nxb\n" =~ m'(?!\A)x'm, "Match failed on re test 3");
assert("a\nb\n" !~ m'b\s^'m, "Match failed on re test 4");
assert("foo\n" =~ m'(?m:(foo\s*$))', "Match failed on re test 5");
assert($1 eq "foo\n", "Capture group failed on re test 5");

# Test matching a pattern with backreferences
my $string2 = "test\nmore test";
assert($string2 =~ /(test).*\1/ms, "Match failed with backreferences");

# Test replacing a pattern with a string
my $replaced = $string;
$replaced =~ s/test/experiment/m;
assert($replaced eq "This is a experiment string\nwith multiple lines", "Replacement failed");

# Test replacing a pattern with a capture group
$replaced = $string;
$replaced =~ s/.*(test).*lines/$1/ms;
assert($replaced eq "test", "Replacement with capture group failed");

# Now on to the issue at hand:

my $message = "message\n";
my $stamp='[stamp]';
$message =~ s/^/$stamp/gm;
assert($message eq "[stamp]message\n", "Original sub failed");

$message = "message\n";
$message =~ s/(?m)^/$stamp/g;   # Specify the 'm' flag in the pattern
assert($message eq "[stamp]message\n", "Original sub with (?m) failed");

$message = "message\n\nmes\nmmm";
$message =~ s/^/$stamp/gm;
assert($message eq "[stamp]message\n[stamp]\n[stamp]mes\n[stamp]mmm", "Main sub failed");

$message = "message\n\nmes\nmmm";
$message =~ s/(?m:^)/$stamp/g;
assert($message eq "[stamp]message\n[stamp]\n[stamp]mes\n[stamp]mmm", "Main sub2 failed");

$message = "message\n\nmes\nmmm";
$message =~ s/^m/$stamp/gm;
assert($message eq "[stamp]essage\n\n[stamp]es\n[stamp]mm", "Second sub failed");

$message = "message\n\nmes\nmmm";
$message =~ s/mes|^/$stamp/gm;
assert($message eq "[stamp]sage\n[stamp]\n[stamp]\n[stamp]mmm", "Third sub failed");

$message = "message\n\nmes\nmmm";
$message =~ s/$/$stamp/gm;
assert($message eq "message[stamp]\n[stamp]\nmes[stamp]\nmmm[stamp]", "Fourth sub failed");

my $pattern = qr(^)m;
$message = "message\n\nmes\nmmm";
$message =~ s/$pattern/$stamp/g;
assert($message eq "[stamp]message\n[stamp]\n[stamp]mes\n[stamp]mmm", "Sub with qr failed");

$message = "message\n\nmes\nmmm";
$message =~ s/[^m]/x/mg;        # Put the '^' in a char class - shouldn't modify it
assert($message eq "mxxxxxxxxmxxxmmm", "Sub with char class failed");

print "$0 - test passed!\n";
