# issue s258 - use Package qw/function.../ needs to import the function into the local package's namespace
package issue_s258;
our $DefaultClass = 'issue_s258';
use lib '.';
use issue_s258m qw/escape/;
use Carp::Assert;

sub new { bless {}, shift }
sub test {
    my $self = shift;
    return $self->escape(shift);
}

assert(escape('abc') eq 'abc');
assert(issue_s258m::escape('abc') eq 'abc');
assert(issue_s258::escape('abc') eq 'abc');
assert(issue_s258->escape('abc') eq 'abc');
my $obj = new issue_s258;
assert($obj->test('abc') eq 'abc');
print "$0 - test passed!\n";
