# issue s306 - If a function has a replacement in scalar context, it shouldn't be replaced if it's being indexed
use Carp::Assert;

my $mday = (CORE::localtime())[3];
assert($mday >= 1 && $mday <= 31);

# issue from cmt/setroutes:

my $xpvcseg;
get_xpvcseg(0);
assert($xpvcseg == 0);
get_xpvcseg(1);
assert($xpvcseg == 12);

sub get_xpvcseg
{
    my $arg = shift;

    return if $arg == 0;
    $in = '12 2 3 4';
    $xpvcseg = (split(/ /,$in))[0];
}

print "$0 - test passed!\n";
