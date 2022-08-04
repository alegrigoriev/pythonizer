# issue s92: while(defined (my $var = readdir(DIR)))) generates incorrect code
use Carp::Assert;

opendir(DIR, '.');
my $ctr = 0;
while(defined(my $file = readdir(DIR))) {
    if($file =~ /\.pl$/) {
        $ctr++;
    }
}

assert($ctr > 200);

print "$0 - test passed!\n";
