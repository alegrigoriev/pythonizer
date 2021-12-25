# issue 101: Bad code generated for pattern match with complex LHS
use Carp::Assert;

@lines = ('real line', '!line1', '!line2');
my $cnt = 0;
while (not (($line = shift @lines) =~ /^!/)) {
    $cnt++;
    assert($line eq 'real line');

}
assert($cnt == 1);

print "$0 - test passed!\n";
