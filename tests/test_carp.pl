# test the carp package

use Carp::Assert;
use Carp qw(carp confess croak cluck shortmess longmess);
use Carp;
#$Carp::Verbose = 1;

$| = 1;

sub subinner {
    local *STDERR;
    open(STDERR, '>tmp.tmp');
    carp "carp message";
    cluck "cluck", " message";

    eval {
        croak "croak message";
        assert(0);
    };
    print STDERR "$@";

    eval {
        confess "confess ", "message";
        assert(0);
    };
    print STDERR "$@";

    print STDERR longmess("longmess message");
    print STDERR shortmess("shortmess ", "message");
    close(STDERR);
}

sub subouter {
    subinner('arg1', 'arg2');
}

subouter(1,2);

open(FD, '<tmp.tmp');
my %has_traceback = (confess=>1, cluck=>1);

my $expect_traceback = 0;
my $found = '';
my $checked = 0;
while(<FD>) {
    if(/^[a-z]/) {
        assert(0) if($expect_traceback);        # Traceback is missing!
        assert(/^(\w+) message at (.*) line (\d+)[.]$/);
        my $func = $1;
        my $source =$2;
        my $lno = int($3);
        $found .= $func;
        check_source($source, $lno, $func);
        $expect_traceback = 0;
        if(exists $has_traceback{$func}) {
            $expect_traceback = 2;
        }
    } else {    # Traceback line
        # Perl version can have main::subinner(...) -or- eval {...}
        assert(/^\s+(?:main\:\:)?(\w+)(?:(?:\(.*,.*\))|(?: \{\.\.\.\})) called at (.*) line (\d+)$/);
        my $func = $1;
        my $source = $2;
        my $lno = int($3);
        check_source($source, $lno, $func);
        $expect_traceback-- if($expect_traceback);
    }
}
assert(!$expect_traceback);
assert($found eq 'carpcluckcroakconfesslongmessshortmess');
assert($checked >= 12);

sub check_source
# Check that the given function is listed on the given line of the given file
{
    my ($source, $lno, $func) = @_;
    return if($source eq 'test_carp.pl' && $func eq 'longmess');        # Ignore bug in perl
    open(SRC, '<', $source) or assert(0);
    while($line = <SRC>) {
        if($lno == $.) {
            assert(index($line, $func) >= 0);
            $checked++;
            last;
        }
    }
    close(SRC);
}

print "$0 - test passed!\n";

END {
    eval {
        unlink "tmp.tmp";
    };
}
