# issue s277 - If a signal handler is more than 1 line, bad code is generated
use Carp::Assert;

$SIG{INT} = sub { $got_signal = 1 };

sub test {
    local $SIG{INT} = sub
        {
            $signal_received = 1;
        };

    0;

}

$SIG{__DIE__} = sub { $bad = 1 };

$SIG{__DIE__} = sub
    { 
       $died = 1;
    };

$SIG{__WARN__} = sub
    {
        print $_[0];
    };

sub test_warn {
    local $SIG{__WARN__};
}
test_warn();

sub test_die {
    local $SIG{__DIE__};
}
test_die();

assert(!$got_signal);
assert(!$signal_received);
assert(!$died);
assert(!$bad);

warn "$0 -  test passed!\n";
