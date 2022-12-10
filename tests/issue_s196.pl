# issue s196 - pattern match in ? : generates bad code
# Code from CGI.pm
use Carp::Assert;

my $thingy = 'abc:def';
my $package = 'main';
sub get_thingy {
    my($tmp) = $thingy=~/[\':]/ ? $thingy : "$package\:\:$thingy";
    return $tmp;
}
assert(get_thingy() eq 'abc:def');
$thingy = 'abc';
assert(get_thingy() eq 'main::abc');

print "$0 - test passed\n";
