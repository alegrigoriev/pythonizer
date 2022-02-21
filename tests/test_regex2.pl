# Test some regex functions and variables
use Carp::Assert;
#pragma pythonizer -M

# A case from our bootstrap:

sub pre_assign
{
	my $use_default_match = 0;
	my $j = 1;
	$ValClass[0] = 'q';
	$ValClass[$j] = 0;	# Mix the types
	$DEFAULT_MATCH = '_m';
	$ValPy[$j] = 0;
	$ValPy[0] = "$DEFAULT_MATCH:=42";
	for(my $i = 0; $i <= 1; $i++) {
	    if($ValClass[$i] eq 'q' && ($ValPy[$i] =~ /$DEFAULT_MATCH:=/)) {
	          $use_default_match = 1;
		  last;
	    }
        }
	assert($use_default_match == 1);
}
pre_assign();

# one from Pass0.pm:


$vp = 'abc';
$flag = 'b';

if($vp =~ /$flag/) {
	$cnt++;
} else {
	assert(0);
}
assert($cnt == 1);
$_ = $vp;
assert(/$flag/);

print "$0 - test passed!\n";

