# Test __dunder__ and CORE references
use v5.16;
use Carp::Assert;
use subs 'sqrt';

assert(__PACKAGE__ eq 'main');	# __PACKAGE__ => __PACKAGE__
assert(! defined __SUB__);
my $line = __LINE__;
assert(__FILE__ =~ /test_dunder_and_core/);

assert($line >= 8 && $line <= 120);

sub sqrt
{
	assert( __SUB__ == \&sqrt);
	return -1;
}

assert(sqrt(4) == -1);
assert(&::sqrt(4) == -1);
assert(CORE::sqrt(4) == 2);

package tester;
use Carp::Assert;
assert(__PACKAGE__ eq 'tester');
assert(<DATA> =~ /line 1/);
assert(!defined <DATA>);
close DATA;

print "$0 - test passed!\n";

__DATA__
line 1
