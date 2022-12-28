# Error test - Tied Array must have POP/SHIFT and/or DELETE to implement pop operations
# pragma pythonizer -M
use Carp::Assert;
sub TIEARRAY { bless [], shift; }

tie my @a, 'main';
eval {
    $a[0] = 1;              # No STORE
};
assert($@ =~ /STORE/);

print "$0 - test passed!\n";

