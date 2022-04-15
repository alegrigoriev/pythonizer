# issue s59 - Don't insert _list_of_n if the RHS contains the same # of elements as the LHS

use Carp::Assert;

# Cases that don't need list_of_n:

my ($a) = (0);	# this case actually uses it
assert($a == 0);
my ($b, $c) = ("b", "c");
assert($b eq 'b' && $c eq 'c');
($d, $e, $f) = ($a, $b, $c);
assert($d == 0 && $e eq 'b' && $f eq 'c');
my ($g, $h) = qw/g h/;

# Cases that need list_of_n:

my $ma = 5;
@a = qw/i j/;
my ($i, $j) = @a;
$ma++;
assert($i eq 'i' && $j eq 'j');
($k, $l, $m) = ('k', 'l', 'm', 'extra');
$ma++;
assert($k eq 'k' && $l eq 'l' && $m eq 'm');
my ($n, $o) = qw/n o p/;
$ma++;
assert($n eq 'n' && $o eq 'o');

if($0 =~ /\.py$/) {
	open($fh, '<', "$0");
	@lines = <$fh>;
	$matches = grep (/list_of_n/, @lines);
	assert($matches == $ma);
}

print "$0 - test passed!\n";
