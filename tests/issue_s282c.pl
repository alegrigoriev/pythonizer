# issue s282c - Implement $^S - this test makes sure we do NOT generate the extra code for eval if we don't reference $^S
use Carp::Assert;

sub evalsub {
    $cnt++;
}

eval {
    evalsub();
};
assert(!$@, 'Test in eval failed!');
assert($cnt == 1, 'cnt is wrong');

my $py = ($0 =~ /\.py$/);

if($py) {
    open(PY, "<$0") or die "Can't open $0";
    while(<PY>) {
        my $pattern = uc 'exceptions_being_caught';
        assert(!/$pattern/, "Found $pattern in line $.");
    }
    close(PY);
}

print "$0 - test passed!\n";
