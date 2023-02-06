# issue s263 - sub that has an if(/else) and ends with a for loop returns early
use Carp::Assert;

my $cnt = 0;
sub test {

    if($_[0]) {
        $i = 2;
    } else {
        $i = 4;
    }

    for(my $j = 0; $j <= $i; $j++) {
        $cnt++;
    }
}

test(2);

#print "$cnt\n";
assert($cnt == 3);

print "$0 - test passed!\n";
