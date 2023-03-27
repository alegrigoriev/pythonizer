# issue s309 - LINE XXX [Pythonizer-W2556]: Cannot get function type for _reset_each (_reset_each in python)
use Carp::Assert;

package DBI;
%installed_drh = ();

package main;

sub disconnect_all {
    keys %DBI::installed_drh; # reset iterator
    while ( my ($name, $drh) = each %DBI::installed_drh ) {
	   $drh->disconnect_all() if ref $drh;
    }
}

my $slice = {k1=>'v1', k2=>'v2'};

my ($k, $v) = each %$slice;
assert($$slice{$k} eq $v);
keys %$slice;      # Reset the iterator
my $cnt = 0;
while( my ($idx, $name) = each %$slice ) {
    assert($$slice{$idx} eq $name);
    $cnt++;
}
assert($cnt == 2);

print "$0 - test passed!\n";
