# test that shift isn't interpreted as a here doc
# inspired by https://github.com/Perl-Critic/PPI/issues/183
use Carp::Assert;

sub bar { return 8 }

sub foo
{
	return 1<<bar();
}

assert(foo() == 256);

print "$0 - test passed!\n";
