# issue s313 - LINE XXXX [Perlscan-S5363]: Unterminated string starting at line YYYY
use Carp::Assert;
package MyClass;
sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    return $self->{$key};
}
package main;

my $key = 'Taint';
my $h = new MyClass('TaintIn' => 1, 'TaintOut' => 1);

# NOTE: The issue occurs due to the lack of a space after the 'eq' operator:
my $result = ($h->FETCH('TaintIn') && $h->FETCH('TaintOut')) if $key eq'Taint';
assert($result);

print "$0 - test passed!\n";
