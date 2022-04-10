# Having multiple statements in map {...} or grep {...} generates bad code
use Carp::Assert;

my $curdir = '.';

if ( !opendir $d, $curdir ) {
    assert(0);
    @files = ();
}
else {
    if ( 1 ) {
        @files = map { /\A(.*)\z/s; $1 } readdir $d;
	#@files = map sub {$_ = $_[0]; /\A(.*)\z/s; $1} , readdir $d;
    }
    else {
        @files = readdir $d;
    }
    closedir $d;
}

#print "@files\n";

my $issues = 0;
my $tests = 0;
for my $f (@files) {
	$issues++ if $f =~ /^issue.*\.pl$/;
	$tests++ if $f =~ /^test.*\.pl$/;
}
assert($issues >= 150);
assert($tests >= 75);

print "$0 - test passed!\n";
