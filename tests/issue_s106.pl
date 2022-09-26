# issue s106 - undefined variable on local foreach loop counters
# Based on get_bravo_demands.pl
use Carp::Assert;

open GVTPDMD, ">tmp.tmp";
close(GVTPDMD);
open GVTPDMD, "tmp.tmp";

while(<GVTPDMD>) {
	my ($sdp, $d, $p) = split /\,/, $_;
	assert(0);	# Shouldn't get here
}

close(GVTPDMD);
unlink "tmp.tmp";

%equivdmd = (a=>'a', b=>'b');

my $ctr = 0;
foreach $p (keys %equivdmd) {
	$ctr++;
	assert($equivdmd{$p} eq $p);
}
assert($ctr == 2);
foreach $p (keys %equivdmd) {
	$ctr++;
	assert($equivdmd{$p} eq $p);
	$raw_gravity{$p} = $p;
}
assert($ctr == 4);

for $sdp (keys %raw_gravity) {
	$ctr++;
	assert($raw_gravity{$p} eq $p);
}
assert($ctr == 6);

%output = (out=>'put');
foreach $k (keys %output) {
	$ctr++;
	assert($output{$k} eq 'put');
}
assert($ctr == 7);

%border = (bor=>'der');
foreach $k (keys %border) {
	$ctr++;
	assert($border{$k} eq 'der');
}
assert($ctr == 8);

# extra tests (not in original code)

# Use a keyword for the variable

$false = 0;
$class = 'c' if $false;
foreach $class (1, 2) {
	$ctr += $class;
}
assert($ctr == 11);

# keyword in a sub
sub useclass {
	foreach $class (3, 4) {
		$ctr += $class;
	}
	assert($ctr == 18);
}
useclass();

# overloaded name
@name = ();
$name = 'n' if $false;
foreach $name (5, 6) {
	$ctr += $name;
}
assert($ctr == 29);

# new var in a sub
sub usenew {
	$new = 0 if $false;
	foreach $new (7, 8) {
		$ctr += $new;
	}
	assert($ctr == 44);
}
usenew();

print "$0 - test passed!\n";
