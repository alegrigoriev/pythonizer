# test pragma pythonizer
use Carp::Assert;
# pragma pythonizer -M

$global_var = 1;

if($0 =~ /\.py$/) {
    if(!open(SOURCE, '<', $0)) {
        assert(0);
    }
    my $match = 0;
    while(<SOURCE>) {
        $match = 1 if(/main\.global_var/);
    }
    assert($match);
}

assert($global_var == 1);

print "$0 - test passed!\n";
