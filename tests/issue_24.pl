# issue 24 - shift without an argument and not in a sub should shift @ARGV

use Carp::Assert;

BEGIN {
    @ARGV = qw/arg0 arg1 arg2 arg3 arg4/;
    my $a0 = shift;
    assert($a0 eq 'arg0');
}
INIT {
    my $a4 = pop;
    assert($a4 eq 'arg4');
}


# shift ARRAY
# shift
#
# Shifts the first value of the array off and returns it, shortening the array by 1 and moving everything 
# down. If there are no elements in the array, returns the undefined value. 
#
# If ARRAY is omitted, shifts the @_ array within the lexical scope of subroutines and formats, 
# and the @ARGV array outside a subroutine and also within the lexical scopes established by
# the eval STRING, BEGIN {}, INIT {}, CHECK {}, UNITCHECK {}, and END {} constructs.
#

unshift(@ARGV, '-e') unless $ARGV[0] =~ /^-/;

$arg0 = shift;
$arg1 = shift;
my $arg2 = shift;

assert($arg0 eq '-e');
assert($arg1 eq 'arg1');
assert($arg2 eq 'arg2');
assert($ARGV[0] eq 'arg3');

END {
    assert($ARGV[0] eq 'arg3');
    my $arg3 = shift;
    assert($arg3 eq 'arg3');
    assert(!@ARGV);
    $? = 0;             # Should give a warning at translate time
}

sub mySub
# Check that shift and pop still work properly in a sub
{
    my $a1 = shift;
    my $aN = pop;

    assert($a1 eq 'a1');
    assert($aN eq 'aN');
    assert($_[0] eq 'a2');
}

mySub('a1', 'a2', 'aN');

print "$0 - test passed!\n";
