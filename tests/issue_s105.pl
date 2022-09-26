# issue s105 - newline at end of filename gets stripped by perl
use Carp::Assert;

$rawfile = "$0\n";

if (not open(FILE,"$rawfile")) {
	print "cannot open $rawfile: $!";
	assert(0);
}

close(FILE);
open(FILE, "<$rawfile") or assert(0);
close(FILE);

$file = "tmp.tmp";
unlink $file if(-f $file);
$fileNL = "$file\n";
open(FILE, ">$fileNL") or assert(0);
close(FILE);
open(FILE, "$file") or assert(0);
close(FILE);
open(FILE, "<$file") or assert(0);
close(FILE);
open(FILE, "<$fileNL") or assert(0);
close(FILE);

END {
	eval { unlink $file; };
}

print "$0 - test passed!\n";
