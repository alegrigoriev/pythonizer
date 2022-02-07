# issue 59 - The functions ord, chr, print, and say should default to $_ if no arg is given

use v5.10;
use Carp::Assert;

$_ = 'a';
$o = ord;
assert(ord == $o);
assert($o == ord);
assert($o == 0x61);

$_ = 0x61;
$c = chr;
assert(chr eq $c);
assert($c eq chr);
assert($c eq 'a');

sub test_say_print
{
    local *STDOUT;
    open(STDOUT, ">tmp.tmp");
    $_ = 'a';
    print;
    print STDOUT;
    say;
    say STDOUT;
    close(STDOUT);
    open(FH, "<tmp.tmp");
    assert(<FH> eq "aaa\n");
    assert(<FH> eq "a\n");
    close(FH);
}

test_say_print();

print "$0 - test passed!\n";

END {
    eval {
        close(FH);
    };
    eval {
        unlink "tmp.tmp";
    };
}
