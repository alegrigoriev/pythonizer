# issue s233 - Defining my own sub croak causes infinite recursion if it calls Carp::croak
use Carp::Assert;
sub croak   { require Carp; Carp::croak(@_)   }

eval { &::croak('nope') };
assert($@ =~ /nope/);

print "$0 - test passed\n";
