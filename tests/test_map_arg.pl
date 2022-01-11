# Test of map as sub arg

use Carp::Assert;

my @arr = (1.25, 2.25, 3.75);

sub sum
{
    $sum = 0;

    foreach my $i (@_){
        $sum += $i;
    }
    $sum
}

assert(sum(1,2,3) == 6);
assert(sum(@arr) == 1.25+2.25+3.75);
assert(sum(map(int, @arr)) == 1+2+3);
assert(sum(map{int($_)} @arr) == 1+2+3);

print "$0 - test passed!\n";
