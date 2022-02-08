# test q - test using a q and friends as a hash key

use Carp::Assert;

my %h = (y=>'y', q=>'q', qq=>'qq', qr=>'qr', qw=>'qw', wr=>'wr', qx=>'qx',
         m=>'m', s=>'s', tr=>'tr', eq=>'eq', ne=>'ne', lt=>'lt', gt=>'gt',
         le=>'le', ge=>'ge', sub=>'sub', and=>'and', if=>'if');

assert($h{y} eq 'y');
assert($h{m} eq 'm');
assert($h{eq} eq 'eq');

for $k (keys %h) {
    assert(%h{$k} eq $k);
}

print "$0 - test passed!\n";
