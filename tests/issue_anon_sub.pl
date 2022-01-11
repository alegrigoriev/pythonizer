# Issue with anonymous subs not being handled
# Code from ./PyModules/LWP/Protocol.pm 
use Carp::Assert;

$SIG{ALRM} = sub { die "timeout"; };
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) }; # SNOOPYJC
$SIG{ INT } = sub { Carp::confess( @_ ) };             # SNOOPYJC
$SIG{ __DIE__ } = 'DEFAULT';
$s = $SIG{ALRM};
$SIG{ALRM} = sub { $my_flag = 1; };
$SIG{ALRM} = sub { $my_flag++; };
$SIG{ALRM} = $s;
$SIG{ALRM} = 'WHO KNOWS';
$SIG{ALRM} = 'IGNORE';
$SIG{ALRM} = 'DEFAULT';
$SIG{ALRM} = sub { die "timeout"; };

*mysub = sub { return 5; };

sub locl
{
    local $SIG {__WARN__} = \&__capture;

    eval {
        local $SIG{'__WARN__'} = sub {
            _diag("Watchdog warning: $_[0]"); }
    };

    # Load POSIX if available
    eval { require POSIX; };

    # Alarm handler will do the actual 'killing'
    $SIG{'ALRM'} = sub {
            select(STDERR); $| = 1;
            _diag($timeout_msg);
            POSIX::_exit(1) if (defined(&POSIX::_exit));
            my $sig = $is_vms ? 'TERM' : 'KILL';
            kill($sig, $pid_to_kill);
    };

    local $SIG{__WARN__} = sub { $@ = shift };
    local $SIG{__WARN__} = sub { $w = shift };
    local $SIG{__WARN__} = sub { $WARN = shift };
}

*LOCAL = *GLOBAL = \&locl;


sub collect
{
    my ($self, $arg, $response, $collector) = @_;

    my $response = {};

    my $fh;

    push(@{$response->{handlers}{response_done}}, {
                    callback => sub {
                        close($fh) or die "Can't write to '$arg': $!";
                        undef($fh);
                    },
                });

     while ($content = &$collector, length $$content) {
         $content_size += length($$content);
         # more here
     }

}

sub collect_once
{
    my ($self, $arg, $response) = @_;
    my $content = \ $_[3];
    my $first = 1;

    $self->collect($arg, $response, sub {
	return $content if $first--;            # Gonna need a 'nonlocal' declaration
	return \ "";
    });
}

print "$0 - test passed!\n";
