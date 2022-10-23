# issue s124 - boolean values should print or convert to strings as 1 or '', not True/False
use Carp::Assert;

my $true = 1 > 0;
my $f = $false = 0 > 1;
my $t = 1 > 0 || 0 > 1;

assert(($true . ', ' . $false) eq '1, ');
assert("$t, $f" eq '1, ');
open(OUT, '>tmp.tmp') or die "Cannot create tmp.tmp";
my $print_result1 = print OUT $true, ', ', $false, "\n";
close(OUT);
open(IN, 'tmp.tmp') or die "Cannot open tmp.tmp";
my $contents = <IN>;
close(IN);
unlink "tmp.tmp";
assert($contents eq "1, \n");

$hash{$print_result1} = 1;
assert(exists $hash{1} && $hash{1} == 1);
assert(!exists $hash{True});
assert($hash{1 > 0} == 1);

my $print_result = print OUT "closed file\n";	# should be ''
$hash{$print_result} = 2;
assert(exists $hash{''} && $hash{''} == 2);
assert(!exists $hash{False});
assert($hash{0 > 1} == 2);

sub TRUE { 1 > 0 }
sub FALSE { 0 > 1 }
assert((TRUE() . ', ' . FALSE()) eq '1, ');

sub Identity
{
	return $_[0];
}
assert((Identity(1 > 0) . ', ' . Identity(0 > 1)) eq '1, ');

sub Chain
{
	return $_[0] . ', ' . $_[1];
}
assert(Chain(1 > 0, 0 > 1) eq '1, ');
assert(Chain(1 > 0 || 0, 0 > 1 && 1 > 0) eq '1, ');

$str = (1>0) . (0>1);
assert($str eq '1');

assert(chr(1 > 0) eq "\x1");

$array[0 > 1] = 2;
$array[1 > 0] = 1;
assert(scalar(@array) == 2);
assert($array[0] == 2);
assert($array[1] == 1);
$array[2] = $array[1 > 0];
assert($array[2] == $array[1]);
assert($array[1 > 0] == $array[1]);

assert((1 > 0) + (1 > 0) == 2);
assert((1 < 0) + (1 < 0) == 0);

assert(substr(1 > 0, 0, 1) eq '1');
assert(substr(1 == 0, 0, 1) eq '');

if(0 > 1) {			# Should not generate a converter
	assert(0);
}
if($hash{0 > 1} == 2) {		# Should generate a converter here
	;
} else {
	assert(0);
}
assert(0) if(0 > 1);		# Should not generate a converter
assert(0) if 0 > 1;		# Should not generate a converter

($hash{0>1}, $hash{1>0}) = (4, 5);
assert($hash{''} == 4);
assert($hash{1} == 5);

my $v = 1 > 0 ? 42 : 43;
assert($v == 42);
$v = 0 > 1 ? 42 : 43;
assert($v == 43);
$v = (1 > 0) ? 42 : 43;		# Should not generate a converter
assert($v == 42);

if(Chain(1 > 0, 0 > 1) eq '1, ') {
	;
} else {
	assert(0);
}

if(($v == 42) or ($v == 43)) {	# Should not generate a converter
	;
} else {
	assert(0);
}

# from updatesender.pl:
$issuesfile = "tmp.tmp";
open(FILE, '>', $issuesfile);
close(FILE);
$issues = (-e $issuesfile && -s $issuesfile > 0);
assert($issues == 0);

END {
	eval {
		unlink $issuesfile;
	};
}

print "$0 - test passed!\n";

