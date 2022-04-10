# issue s45 - warnings should be off by default
use Carp::Assert;

close(STDERR);
open(STDERR, '>', 'tmp.tmp');

my $num = 'null';
assert($num == 0);		# no warning


$num = 'nope';
{
	use warnings qw/numeric/;
	assert($num == 0);	# generates a warning
}

close(STDERR);

open(FD, '<tmp.tmp');
my $msg = <FD>;
assert($msg =~ /nope.*numeric/);
close(FD);

print "$0 - test passed!\n";

END {
	eval { close(STDERR) };
	eval { close(FD) };
	eval { unlink "tmp.tmp" };
}
