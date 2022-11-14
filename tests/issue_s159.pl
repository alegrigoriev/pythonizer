# issue s159 - grep regex generates bad code
use Carp::Assert;

$currentdir = '.';
if ( opendir(DIR, $currentdir) ) {
    my @files = grep /issue_s159.pl$/, readdir(DIR);
    assert(@files == 1);
} else {
    assert(0);
}

print "$0 - test passed!\n";
