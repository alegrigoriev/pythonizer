# issue s111 - conditional require not being changed from .pl to .py
# Code from dcInit.pl
use Carp::Assert;

my $ScriptDir = '.';

if ( -e "$ScriptDir/debug.pl") {		# Does not exist
	require "$Scriptdir/debug.pl";
}

assert(!defined $Debug);

$ScriptDir = "./subdir";

if ( -e "$ScriptDir/debug.pl") {		# Exists
	require "$ScriptDir/debug.pl";
}

assert(defined $Debug);


# from dcUtil:
=pod
# We skip this case because the '.pl' is not a path at the start of the string
$tday = 1;
$hour = 2;
DCinfo("Rerun getRPMdata2.pl $tday $hour");

$py = ($0 =~ /\.py/);

sub DCinfo {
    if($py) {
	    assert($_[0] eq "Rerun getRPMdata2.py $tday $hour");
    } else {
	    assert($_[0] eq "Rerun getRPMdata2.p" . "l $tday $hour");
    }
}
=cut

print "$0 - test passed\n";
