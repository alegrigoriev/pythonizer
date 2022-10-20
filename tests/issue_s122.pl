# issue s122 - IO encoding shouldn't default to UTF-8
use Carp::Assert;

my $value = "\x80abc\x91quoted\x92 \x93double quoted\x94 2\xb0\r\n";
open(FILE, '<issue_s122.in') or die "Cannot open issue_s122.in";
my $contents = <FILE>;
close(FILE);

assert($value eq $contents);

open(OUT, '>issue_s122.out') or die "Cannot create issue_s122.out";
print OUT $value;
close(OUT);
my $code = `diff -q issue_s122.in issue_s122.out`;
assert($code eq '');

open(ALL, "issue_s122.all") or die "Cannot open issue_s122.all";
$contents = <ALL>;
chomp $contents;
close(ALL);
for(my $i = 0, $j = 0; $i <= 255; $i++, $j++) {
	my $c = substr($contents, $i, 1);
	$j++ if($i == 10 || $i == 13);	# There is no CR or LF in the data
	assert($c == chr $j);
}

print "$0 - test passed!\n";

END {
	eval {close(OUT);};
	unlink "issue_s122.out";
}
