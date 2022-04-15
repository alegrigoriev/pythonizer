# issue s55: Converting an array into an array ref using [@arr] shouldn't generate an outer array
use Carp::Assert;

my @arr = (1,2,3);
my %hash = (key=>'value');

my $ar = [@arr];
assert($ar->[0] == 1);
assert($ar->[1] == 2);
assert($ar->[2] == 3);

my $ha = {%hash};
assert($ha->{key} eq 'value');

print "$0 - test passed!\n";
