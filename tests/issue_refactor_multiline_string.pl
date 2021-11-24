# Issue where the refactoring messes up on multi-line strings
use Carp::Assert;
assert(my_sub() == 1);

sub my_sub
{
	my $str1 = 'multi-line
string here';
	my $str2 = "multi-line
string here";
	my $s = "string";
	my $str3 = "multi-line
$s here";
	return ($str1 eq $str2 && $str1 eq $str3);
}

print "$0 - test passed!\n";
