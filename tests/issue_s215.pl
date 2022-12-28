# issue s215 - if(keys %$leftover) incorrectly raises an exception if $leftover is undef
# pragma pythonizer -M
use Carp::Assert;

# Try a case where we can guess the type

my $lf;
if(keys %$lf) {
    assert(0, "not supposed to get here");
}
if(keys %{$lf}) {
    assert(0, "not supposed to get here");
}

# Now the case that fails

sub test_leftover0 {
    my $leftover = shift;
    if(%$leftover) {
        assert(0, "not supposed to get here");
    }
    if(keys(%$leftover)) {
        assert(0, "not supposed to get here");
    }
    if(keys %{$leftover}) {
        assert(0, "not supposed to get here");
    }
    if(keys(%{$leftover})) {
        assert(0, "not supposed to get here");
    }
    if(keys %$leftover) {
        assert(0, "not supposed to get here");
    }
    if(values %$leftover) {
        assert(0, "not supposed to get here");
    }
    assert(0, "not supposed to get here") if keys %$leftover;
}

test_leftover0();

# this one uses a mapped global variable

sub test_leftover {
    $leftover = shift;
    if(%$leftover) {
        assert(0, "not supposed to get here");
    }
    if(keys(%$leftover)) {
        assert(0, "not supposed to get here");
    }
    if(keys %{$leftover}) {
        assert(0, "not supposed to get here");
    }
    if(keys(%{$leftover})) {
        assert(0, "not supposed to get here");
    }
    if(keys %$leftover) {
        assert(0, "not supposed to get here");
    } else {
        print "$0 - test passed!\n";
    }
}

test_leftover();

