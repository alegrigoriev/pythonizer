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

# And a case from bootstrapping:

$i = 0;
$ValPy[$i] = 'a b cc';
push @libs, map {'"'.$_.'"'} split(' ', $ValPy[$i]);
assert(@libs == 3);
assert($libs[0] eq '"a"');
assert($libs[1] eq '"b"');
assert($libs[2] eq '"cc"');

print "$0 - test passed!\n";
