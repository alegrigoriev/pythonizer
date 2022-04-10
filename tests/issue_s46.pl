# issue s46 - Non-parenthesized function call with | operator isn't parsed properly
use Carp::Assert;
use File::stat;

my $st = stat('.');

my $perm = $st->mode;

my $root = '.';

if( !chmod $perm | oct '700', $root) {
	assert(0);
} else {
	print "$0 - test passed!\n";
}


