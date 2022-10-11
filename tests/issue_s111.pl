# issue s111 - for loop that counts down to 1 not translated properly
use Carp::Assert;

$. = 4;
my $tot;
for(my $lno = $. - 1; $lno; $lno--) {
	$tot++;
}

assert($tot == 3);

print "$0 - test passed\n";
