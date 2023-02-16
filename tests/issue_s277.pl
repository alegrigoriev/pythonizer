# issue s277 - If a signal handler is more than 1 line, bad code is generated

sub test {
    local $SIG{ALRM} = sub
        {
            $signal_received = 1;
        };

    0;

}

print "$0 -  test passed!\n";
