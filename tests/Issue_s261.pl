# issue s261 - Assignment to arrayref and hashref changes the location of the object so the original object is not updated
use Carp::Assert;
no warnings 'experimental';
sub test_arr {
    my $arrref = $_[0];

    @repl = (4,5);

    @$arrref = @repl;
}

sub test_hash {
    my $hashref = $_[0];

    %repl = (k3=>3, k4=>4);

    %$hashref = %repl;
}

my @arr = (1,2,3);
test_arr(\@arr);
assert(@arr ~~ [4,5]);

my %hash = (k1=>1, k2=>2, k3=>3);
test_hash(\%hash);
assert(%hash ~~ {k3=>3, k4=>4});

print "$0 - test passed!\n";


