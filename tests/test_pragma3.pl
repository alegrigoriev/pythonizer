# test pragma pythonizer
use Carp::Assert;
# pragma pythonizer implicit global my, TRACEback

$global_var = 1;
%hash = ();

if($0 =~ /\.py$/) {
    if(!open(SOURCE, '<', $0)) {
        assert(0);
    }
    my $match = 0;
    my $h = 0;
    my $tb = 0;
    my $main = 'main';
    while(<SOURCE>) {
        $match = 1 if(/$main\.global_var/);
        $h = 1 if(/Hash[(]/);
        $tb = 1 if(/perllib[.]TRACEBACK/);
    }
    assert(!$match);
    assert($h);
    assert($tb);
}

assert($global_var == 1);

print "$0 - test passed!\n";
