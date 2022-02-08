# test pragma pythonizer
use Carp::Assert;
# pragma pythonizer -mA

$global_var = 1;

if($0 =~ /\.py$/) {
    if(!open(SOURCE, '<', $0)) {
        assert(0);
    }
    my $match = 0;
    my $a = 0;
    while(<SOURCE>) {
        $match = 1 if(/main\.global_var/);
        $a = 1 if(/perllib\.AUTODIE/ || /^AUTODIE/);
    }
    assert(!$match);
    assert($a);
}

assert($global_var == 1);

print "$0 - test passed!\n";
