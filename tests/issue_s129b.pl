# issue s129b - implement switch - part 3 - given and when

use Carp::Assert;
use v5.34;
no warnings qw/experimental/;

my ($abc, $def, $xyz, $nothing);

for my $var ('abc', 'def', 'xyz', 'other') {
    given ($var) {
        when (/^abc/) { $abc = 1 }
        when (/^def/) { $def = 1 }
        when (/^xyz/) { $xyz = 1 }
        default       { $nothing = 1 }
    }
}
assert("${abc}${def}${xyz}$nothing" eq '1111');

for my $var ('abc', 'def', 'xyz', 'other') {
    for ($var) {
        $abc++ when /^abc/;
        $def++ when /^def/;
        $xyz++ when /^xyz/;
        default { $nothing++ }
    }
}
assert("${abc}${def}${xyz}$nothing" eq '2222');

for my $var ('abc', 'def', 'xyz', 'other') {
    given ($var) {
        $abc = 1 when /^abc/;
        $def = 1 when /^def/;
        $xyz = 1 when /^xyz/;
        default { $nothing = 1 }
    }
}
assert("${abc}${def}${xyz}$nothing" eq '1111');

# try a nested one
for my $var ('abc', 'def', 'xyz', 'other') {
    given ($var) {
        when (/^\w\w\w$/) { 
            given ($var) {
                when (/^abc/) { $abc = 1 }
                when (/^DEF/i) { $def = 1 }
                when (/^xyz/) { $xyz = 1 }
            }
        }
        default       { $nothing = 1 }
    }
}
assert("${abc}${def}${xyz}$nothing" eq '1111');

# try break and continue
my ($x, $y, $def);

for my $foo ('xx', 'yy', 'xy', 'xyz', 'other') {
    given($foo) {
        when (/x/) { $x++; 
                     break if $foo eq 'xyz'; 
                     continue; }
        when (/y/) { $y++; }
        default    { $def++; }
    }
}
assert("${x}${y}$def" eq '322');

# try out $_

for my $var ('abc', 'def', 'xyz', 'other') {
    given ($var) {
        when (/^abc/) { $abc = 2; assert($_ eq 'abc') }
        when (/^def/) { $def = 2; assert($_ eq 'def') }
        when (/^xyz/) { $xyz = 2; assert($_ eq 'xyz') }
        default       { $nothing = 2; assert($_ eq 'other') }
    }
}
assert("${abc}${def}${xyz}$nothing" eq '2222');

print "$0 - test passed\n";
