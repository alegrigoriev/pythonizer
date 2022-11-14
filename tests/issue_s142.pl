# issue s142 - autovivification doesn't work on $ARGV 
use Carp::Assert;

my $args = "$ARGV[0] $ARGV[1]";

assert($args eq ' ');

assert($ARGV[0] eq '');
assert($ARGV[1] eq '');

@ARGV = ('arg1', 'arg2');

assert("$ARGV[0] $ARGV[1] $ARGV[2]" eq 'arg1 arg2 ');
assert($ARGV[0] eq 'arg1');
assert($ARGV[1] eq 'arg2');
assert($ARGV[2] eq '');

@ARGV[2..3] = ('arg3', 'arg4');
assert($ARGV[0] eq 'arg1');
assert($ARGV[1] eq 'arg2');
assert($ARGV[2] eq 'arg3');
assert($ARGV[3] eq 'arg4');

$ARGV[4] = 'arg5';
assert($ARGV[4] eq 'arg5');

print "$0 - test passed!\n";
