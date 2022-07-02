#!/usr/bin/perl
# issue s86 - If a perl script mentions it's own filename, it should be pythonized to the python filename
use Carp::Assert;

logit("passed", "issue_s86.pl");

sub logit
{
	my ($arg1, $arg2) = @_;

	$py = ($0 =~ /\.py$/);
	if($py) {
		assert($arg2 eq 'issue_s86.py');
	} else{
		assert($arg2 eq 'issue_s86.pl');
	}
	print "$arg2 - test $arg1!\n";
}
