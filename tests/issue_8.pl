use Carp::Assert;
sub issue_8
{
	$arg1 = shift;
	my $arg2 = shift;

        assert($arg1 == 1 && $arg2 == 2);
}

issue_8(1, 2);
print "$0 - test passed!\n";
