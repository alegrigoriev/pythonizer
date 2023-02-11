# issue s272 - Conditional $DB::single assignment generates unconditional call to pdb
use Carp::Assert;
my $val = 1;
$DB::single = 1 if $val == 2;
my $py = ($0 =~ /\.py$/);
if($py) {
    open(PY, "<$0");
    my @lines = <PY>;
    assert(grep { /if val == 2:/ } @lines);
    assert(grep { /    perllib\.set_breakpoint\(\)/ } @lines);
}
print "$0 - test passed!\n";
