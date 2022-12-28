# issue s218 - Return with ||= generates bad code (and object comparison is broken) 

package issue_s218;
use Carp::Assert;

my $Q;
sub TIEHASH {
    my $class = shift;
    return $Q ||= $class->new;
}

sub SCALAR {
    return 0;
}

sub FIRSTKEY { undef }
sub NEXTKEY  { undef }

sub new { bless {}, shift }

my $o = issue_s218->TIEHASH;

assert(ref($o) eq 'issue_s218');
my $p = new issue_s218;
assert(ref($p) eq 'issue_s218');
assert($o != $p);
$Q = $o;
my $q = issue_s218->TIEHASH;
assert($q == $o);

print "$0 - test passed!\n";
