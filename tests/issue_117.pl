# issue 117: Calling a subroutine as &mySub; needs to pass in @_

use Carp::Assert;

sub mySub
{
	my ($arg1, $arg2) = @_;

	assert($arg1 == 1 && $arg2 == 2);
}

sub main
{
	shift;
	&mySub;
}

main(0, 1, 2);
mySub(1,2);
&mySub(1,2);

my $subref = \&mySub;

&{$subref}(1,2);

print "$0 - test passed!\n";
