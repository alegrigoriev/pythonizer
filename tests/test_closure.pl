# Test closure with anon subs per the documentation
use Carp::Assert;

sub newsub {
	my $x = shift;
	return sub { my $y = shift; return "$x, $y!\n"; }
}
$h = newsub("Howdy");
$g = newsub("Greetings");

assert(&$h("world") eq "Howdy, world!\n");
assert(&$g("earthlings") eq "Greetings, earthlings!\n");

print "$0 - test passed!\n";
