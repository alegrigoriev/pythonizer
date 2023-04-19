package A;

use strict;
use warnings;
use A::A;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub hello {
    my $a_a = A::A->new;
    return $a_a->hello;
}

1;
