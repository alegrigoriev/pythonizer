# issue s74: Interesting perl module $VERSION calculation line generates wrong code
use Carp::Assert;

our $VERSION = do { my @r = ( q$Revision: 1.3 $ =~ /\d+/g ); sprintf "%d." . "%02d" x $#r, @r };
assert($VERSION eq '1.03');

print "$0 - test passed!\n";
