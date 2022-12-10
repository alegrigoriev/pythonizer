# issue s191 - passing a hash to a sub should send the keys and values
use Carp::Assert;

%found = ();
sub get_hash {
    for(my $i = 0; $i < @_; $i++) {
        $_ = $_[$i];
        $found{$_} = 1;
        if(/^k(\d)/) {
            assert($_[$i+1] =~ /^v$1/); # Make sure they are in the right order
        }
    }
}

sub get_hash_ref {
    get_hash(%{$_[0]});
}

my %hash = (k1=>'v1', k2=>'v2');

get_hash(%hash);
assert(exists $found{k1});
assert(exists $found{v1});
assert(exists $found{k2});
assert(exists $found{v2});
%found = ();

get_hash_ref(\%hash);
assert(exists $found{k1});
assert(exists $found{v1});
assert(exists $found{k2});
assert(exists $found{v2});

print "$0 - test passed!\n";

