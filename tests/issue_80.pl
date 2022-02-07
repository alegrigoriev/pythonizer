# issue 80 - Properly interpolate vars in patterns

use Carp::Assert;

my $string = "myDC_2022";
my $year = 2022;
assert($string =~ /DC_$year$/);

print "$0 - test passed!\n";
