# issue s220 - In a sub, unshift(@_, ...) gives a TypeError: 'tuple' object does not support item assignment
use Carp::Assert;

sub test_unshift {
    unshift(@_, 1);
    return @_;
}

my @arr = test_unshift(2);

assert(join(' ', @arr) eq '1 2');

print "$0 - test passed!\n";
