# issue s94 - unlink or die generates incorrect code
use Carp::Assert;

open(FILE, ">tmp.tmp");
close(FILE);
unlink "tmp.tmp" or die "tmp.tmp unlink failed!";

open(FILE, ">tmp.tmp");
close(FILE);
$_ = "tmp.tmp";
unlink or die "tmp.tmp unlink failed!";
assert(! -f "tmp.tmp");

open(FILE, ">tmp.tmp");
close(FILE);
@list = ("not.found1", "tmp.tmp", "not.found2");
my $cnt = unlink @list;
assert($cnt == 1);
assert(! -f "tmp.tmp");

open(FILE, ">tmp.tmp");
close(FILE);
my $cnt = unlink("not.found1", "tmp.tmp", "not.found2");
assert($cnt == 1);
assert(! -f "tmp.tmp");

eval {
	unlink "tmp.tmp" or die "tmp.tmp unlink passed!";
	assert(0);	# shouldn't get here
};
assert($@ =~ /passed/);
assert($! =~ /No such file/ || $! =~ /cannot find the file/);

print "$0 - test passed!\n";
