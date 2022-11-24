# issue s170 - break outside of a given block should raise an exception, not generate a syntax error
# perl generates this error: Can't "break" outside a given block
use v5.14;
no warnings qw/experimental/;
use Carp::Assert;

1 or break;

1 or return;

1 or next;

1 or last;

sub break_it { break }

my $c = 0;
my ($h1, $h2, $h3);
given($c) {
    when (0) { $h1++; continue }
    # Let's not support this: when (/^\d/) { $h2++; break_it(); $h3++ }
    when (/^\d/) { $h2++; break; $h3++ }
}
assert($h1 == 1);
assert($h2 == 1);
assert($h3 == 0);

# Compare break (from given) with last (from for(each))
sub last_it { last }

my ($cnt1, $cnt2);
foreach ('a', 'b') {
    $cnt1++;
    last_it();
    $cnt2++
}
assert($cnt1 == 1);
assert($cnt2 == 0);

# Now combine them both to make sure we are generating the right code

$cnt1 = $cnt2 = 0;
my ($cnt3, $cnt4, $cnt5);
foreach ('a', 'b', 'c', 'd') {
    given ($_) {
        when ('a') { $cnt1++; continue }
        # Not supported: when ('b') { $cnt2++; break_it(); continue }
        when ('b') { $cnt2++; break; continue }
        when (/[b-c]/) { $cnt3++; last_it(); $cnt4++ }
        when ('d') { $cnt5++ }
    }
}
assert($cnt1 == 1);
assert($cnt2 == 1);
assert($cnt3 == 1);
assert($cnt4 == 0);
assert($cnt5 == 0);

print "$0 - test passed!\n";
