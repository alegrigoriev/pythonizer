# issue s275 - Global variable in package sometimes incorrectly replaced with loop-local variable
use Carp::Assert;

BEGIN {
        my $BIGGER_THAN_THIS = 1e30;
    	for my $t (
	    'exp(99999)',  # Enough even with 128-bit long doubles.
	    'inf',
	    '1e99999',
	    ) {
	    local $^W = 0;
        #my $i = eval "$t+1.0";
        my $i = eval {
            $t + 1.0;
        };
	    if (defined $i && $i > $BIGGER_THAN_THIS) {
		$Inf = $i;
		last;
	    }
          }
}

assert(lc $Inf eq 'inf');

my $i;

sub i () {
        return $i if ($i);
	$i = 42;
	return $i;
}

sub root {
   my ($t, $n, $theta_inc) = (4, 2, 2);
   for (my $i = 0, my $theta = $t / $n;
        $i < $n;
        $i++, $theta += $theta_inc) {
        $cnt++;
    }
}

root();
assert($cnt == 2);
assert(i() == 42);

print "$0 - test passed!\n";
