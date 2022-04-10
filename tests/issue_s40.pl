# issue s40 - readdir in list context needs to return all of the entries
use Carp::Assert;

opendir($dh, '.');

# First try one by one
for(;;) {
	my $fn = readdir($dh);
	$issues++ if($fn =~ /^issue.*\.pl$/);
	last if($fn =~ /^test.*\.pl/);
}

$tests++;
my $where = telldir($dh);

# now read the rest in list context
for my $fn (readdir $dh) {
	$issues++ if($fn =~ /^issue.*\.pl$/);
	$tests++ if($fn =~ /^test.*\.pl$/);
}
assert($issues > 150);
assert($tests > 75);

my @rest = readdir $dh;	# Should be none left
assert(@rest == 0);

rewinddir $dh;
@rest = readdir $dh;	# Should get them all
assert(@rest > ($issues + $tests));

my $fn = readdir $dh;	# should be none left again
assert(!defined $fn);

my @rest = readdir $dh;	# Should still be none left
assert(@rest == 0);

# Go back where we were and count again
seekdir($dh, $where);

$tests2 = 1;
# read again rest in list context
#
# From the documentation: If the condition expression of a while statement is 
# based on any of a group of iterative expression types then it gets some magic 
# treatment. The affected iterative expression types are readline, the <FILEHANDLE>
# input operator, readdir, glob, the <PATTERN> globbing operator, and each. If the
# condition expression is one of these expression types, then the value yielded by
# the iterative operator will be implicitly assigned to $_. If the condition
# expression is one of these expression types or an explicit assignment of one of
# them to a scalar, then the condition actually tests for definedness of the
# expression's value, not for its regular truth value.
while(readdir $dh) {
	$tests2++ if /^test.*\.pl$/;
}
assert($tests == $tests2);

# one more time with a variable in the while
seekdir($dh, $where);
$tests2 = 1;
while(my $f = readdir $dh) {
	$tests2++ if $f =~ /^test.*\.pl$/;
}
assert($tests == $tests2);
closedir($dh);

# Test the other iterators too while we are here

open($fh, '<', "$0");
my $start_pos = tell($fh);
my $from_the_doc = 0;
while(<$fh>) {
	$from_the_doc++ if /From the documentation/;
}
assert($from_the_doc == 3);

seek $fh, $start_pos, 0;		# rewind

$from_the_doc = 0;
while(readline($fh)) {
	$from_the_doc++ if /From the documentation/;
}
assert($from_the_doc == 3);
close($fh);

my $str = "The big fox jumped over the little fox";
while($str =~ /fox/g) {
	$foxes++;
}
assert($foxes == 2);

@arr=qw/0 1 2 3 4/;
while(my ($ndx, $val) = each @arr) {
	assert($ndx == $val);
}

print "$0 - test passed!\n";
