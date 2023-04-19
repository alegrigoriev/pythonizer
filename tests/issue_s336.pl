# issue s336 - Assigning a string to a signal handler generates incorrect code unless the string is IGNORE or DEFAULT
use strict;
use warnings;
use Carp::Assert;

# Define the signal handler function
my $caught_int = 0;
sub catch_zap {
    my $signal = shift;
    $caught_int++;
}

# Test signal handler assignment for catch_zap, IGNORE, and DEFAULT
my @handler_values = (\&catch_zap, 'catch_zap', __PACKAGE__ . "::catch_zap", 'IGNORE', 'DEFAULT');

sub test_local_ignore
{
    local $SIG{INT};

    $SIG{INT} = sub { };

    kill 'INT', $$;
}

test_local_ignore();

print STDERR "Expect 2 messages about SIGINT handlers\n";

sub test_invalid
{
    local $SIG{INT};

    $SIG{INT} = 'invalid';
    kill 'INT', $$;
}
test_invalid();

sub test_illegal
{
    local $SIG{INT};

    my $pi = 3.14;
    $SIG{INT} = $pi;
    kill 'INT', $$;
}
test_illegal();

foreach my $handler (@handler_values) {
    # Assign the signal handler to the $SIG{INT} handle
    $SIG{INT} = $handler;
    $SIG{CHLD} = $handler if $^O ne 'MSWin32' && $handler eq 'DEFAULT';

    # Test if the signal handler has been assigned correctly
    #assert($SIG{INT} eq $handler, "Signal handler assigned correctly for $handler.");

    # Send an INT signal to the process to test the handler
    # for DEFAULT: On Unix, send a SIGCHLD, which the default is to Ignore
    #              On Windows, just exit because else our exit code will be non-zero
    if($handler eq 'DEFAULT') {
        if($^O eq 'MSWin32') {
            exit 0;
        } else {
            kill 'CHLD', $$;
        }
    } else {
        kill('INT', $$);
    }

    # If the test is successful, print the appropriate message
    if ($handler eq 'IGNORE') {
        assert($caught_int == 3);
        print "$0 - test passed!\n";
    } elsif ($handler eq 'DEFAULT') {
        #print "Test passed for DEFAULT! (Process terminated)\n";
        assert($caught_int == 3);
    } else {
        #assert($caught_int == 3);
        #print "Test passed for catch_zap! (Caught INT!)\n";
    }
}
