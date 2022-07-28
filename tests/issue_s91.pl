# issue s91 - open with a dynamic single argument that does not contain a mode returns None on error instead of a closed file
use Carp::Assert;

my $nef = "non_existing_file";
if(!open(HOSTS, $nef)) {
    print "$0 - test passed\n";
} else {
    assert(0);  # nope!
}
