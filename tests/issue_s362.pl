# issue s362 - C-style for loop with ++j may generate bad code
use Carp::Assert;

if(1) {     # Needs to be in a conditional
    my $i = 'a';    # mixed type loop counter

    for($i = 0; $i < 10; $i++) {
        $cnt++;
    }
    assert($cnt == 10);
}

print "$0 - test passed!\n";
