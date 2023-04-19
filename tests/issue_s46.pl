# issue s46 - Non-parenthesized function call with | operator isn't parsed properly
use Carp::Assert;
use File::stat;

my $root = '.';

my $st = stat($root);

my $perm = $st->mode & 0777;


if( !chmod $perm | oct '700', $root) {
	assert(0, "chmod $perm failed - $!");
} else {
	print "$0 - test passed!\n";
}


