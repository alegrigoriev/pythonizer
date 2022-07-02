# issue s87 - If a perl script executes another perl script via a file path, optionally replace that with the pythonized version
use Carp::Assert;

$flagvar = 'f';
$output = `./issue_s86.pl`;
$ht = "http://www.myserver.com/mycgi.pl";
$pl = "/rootdir/mypath/to/myfile.pl -flag $flagvar -a";
$plw = "D:\\UserName\\PathTo\\script.pl -arg";

assert($ht eq 'http://www.myserver.com/mycgi.pl');

$py = ($0 =~ /\.py$/);

if($py) {
	assert($pl eq "/rootdir/mypath/to/myfile.py --flag $flagvar -a");
        assert($plw eq "D:\\UserName\\PathTo\\script.py --arg");
	assert($output eq "issue_s86.py - test passed!\n");
} else {
	assert($pl eq "/rootdir/mypath/to/myfile.pl -flag $flagvar -a");
        assert($plw eq "D:\\UserName\\PathTo\\script.pl -arg");
	assert($output eq "issue_s86.pl - test passed!\n");
}

print "$0 - test passed!\n";
