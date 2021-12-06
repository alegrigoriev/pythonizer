# Test ref on basic types
use Carp::Assert;
my $i = 1;
assert(ref \$i == 'SCALAR');
my $f = 1.2;
assert(ref(\$f) == 'SCALAR');
my $s = 'a';
assert(ref(\$s) == 'SCALAR');
my @a = (1, 2);
assert(ref(\@a) == 'ARRAY');
assert(ref \$a[0] == 'SCALAR');
my %h = (a=>2, b=>3);
assert(ref(\%h) == 'HASH');
assert(ref(\$h{a}) == 'SCALAR');
my %hh = (h=>%h);
assert(ref \%hh == 'HASH');
assert(ref \%hh{h} == 'HASH');
print "$0 - test passed!\n";
