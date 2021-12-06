# Test END block
use Carp::Assert;

BEGIN {
    $i = 1;
    $j = 0;
}

END {
    assert($j == 2);
    eval {                      # $0 doesn't work in atexit blocks in python
        print "$0 - test passed!\n";
    };
    if($@) {
        print "test_END.py - test passed!\n";
    }
}

END {
    $j = 2;
}

sub do_something {
    exit;
}

do_something();
