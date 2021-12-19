# issue 95 - Regex with local sub call generated bad code
use Carp::Assert;

sub sub1
{
    return 'sub1';
}

sub sub2
{
    $arg = shift;
}

assert(sub1 =~ /^sub1$/);
assert(sub2('arg') =~ /^arg$/);
assert(sub2 'argb' =~ /^argb$/);
assert(substr('arg',0) =~ /^arg$/);
assert((substr 'arg',0)  =~ /^arg$/);

$_ = ord('a');
assert(chr =~ /^a$/);

my @arr = ('aa', 'bb');
my $i = 0;
assert($arr[$i] =~ /^aa$/);
my %hash = (k1=>'v1');
assert($hash{k1} =~ /^v1$/);

print "$0 - test passed!\n";
