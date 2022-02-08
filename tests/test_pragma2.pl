# test pragma pythonizer
use Carp::Assert;
# pragma pythonizer no implicit global my, no autovivification

$global_var = 1;
%hash = ();

if($0 =~ /\.py$/) {
    if(!open(SOURCE, '<', $0)) {
        assert(0);
    }
    my $match = 0;
    my $h = 0;
    while(<SOURCE>) {
        $match = 1 if(/main\.global_var/);
        $h = 1 if(/Hash[(]/);
    }
    assert($match);
    assert(!$h);
}

assert($global_var == 1);

print "$0 - test passed!\n";
