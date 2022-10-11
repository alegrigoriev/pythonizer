# issue s114: improper interpretation of interpolated string leads to bad code in next sub
# Code from pythonizer (bootstrap)
use Carp::Assert;

sub gen_statement
{
	my $arg = shift;
	assert($arg eq 'sys.argv[1:] = _ap_rem');
}

$ARG_PARSER="_ap";

sub getopts_fun                 # issue s67: implement getopt/getopts
{
    gen_statement("sys.argv[1:] = ${ARG_PARSER}_rem");      # issue 24
    #		   0.........1.........2.........3.
    #		   01234567890123456789012345678901
}

sub GetOptionsHandled           # issue 48: Can we handle this GetOptions call?
{
    my $start = shift;

    assert($start eq 'start');

}

getopts_fun();
GetOptionsHandled('start');

print "$0 - test passed\n";
