# issue 66 - diamond operator with glob expression
use Carp::Assert;
sub THISFILE () {"issue_66.pl"}
$count = 0;
while (<*.pl>) {
	assert(/^issue/ or /^test/);
	$count++;
	last;
}
assert($count);

my $pat = '*.pl';
$count = 0;
while ($pat ) {		# note the space makes it a glob not a readline
	assert(/^issue/ or /^test/);
	$count++;
	last;
}
assert($count);

$count = 0;
while (${pat}) {	# another glob
	assert(/^issue/ or /^test/);
	$count++;
	last;
}
assert($count);

$i = 10;
$j = 20;
assert($i<11&&$j>19);		# Not a diamond operator!

open(FD, THISFILE);
while(<FD>) {
    assert($_ =~ /issue 66/) if($. eq 1);
    last;
}
close FD;
open($fd, THISFILE);
while(<$fd>) {
    assert($_ =~ /issue 66/) if($. eq 1);
    last;
}
@ARGV = (THISFILE);
$did_one = 0;
while(<>) {		# reads THISFILE, not STDIN
    assert($_ =~ /issue 66/) if($. eq 1);
    assert($ARGV =~ /issue_66.pl/);
    $did_one = 1;
    last;
}
assert($did_one);
@ARGV = (THISFILE);
$did_one = 0;
while(<<>>) {		# only can be a literal filename, not a pipe
    assert($_ =~ /issue 66/) if($. eq 1);
    assert($ARGV =~ /issue_66.pl/);
    $did_one = 1;
    last;
}
assert($did_one);
if(0) {
	while(<STDIN>) {	# Manually check the generated code
		;
	}
	while(my $line = <STDIN>) {
		;
	}
}

print "$0 - test passed!\n";
