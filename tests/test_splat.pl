# Test some cases where we spat and ones where we don't
use Carp::Assert;

# from agntm.pl:
#

my $r2 = "a b c";
my $result;
foreach $r (split /\s/,$r2)
{
    $result .= $r;

}

assert($result eq 'abc');

sub subr
{
    my $result;
    foreach $arg (@_) {
        $result .= $arg;
    }
    return $result;
}

assert(subr(split /\s/,$r2) eq 'abc');

my @arr = ('a', 'b', 'c', 'd');

$result = '';
foreach $r (@arr) {
    $result .= $r;
}
assert($result eq 'abcd');

assert(subr(@arr) eq 'abcd');

# from alert_compass.pl:

open(ERR, '>', 'tmp.tmp');
push @failmsg, "error\n";
print ERR @failmsg if (@failmsg);
close(ERR);

open(ERR, '<', 'tmp.tmp');
my $line = <ERR>;
assert($line eq "error\n");
close(ERR);

END {
    eval { close(ERR) };
    eval { unlink('tmp.tmp') };
}

print "$0 - test passed!\n";
