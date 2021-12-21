# issue 107: If you refer to a variable argument, or the last argument number, bad code is generated

use Carp::Assert;
sub varadd
{
    assert(scalar(@_)-1 == $#_);
    my $total = 0;
    for(my $i=0; $i<=$#_; $i++) {
        $total += $_[$i];
    }
    return $total;
}

assert(varadd(2, 2) == 4);
assert(varadd(1,2,3) == 6);
print "$0 - test passed!\n";
