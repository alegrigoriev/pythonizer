package A::B;

use strict;
use warnings;
use A::B::A;
use Carp::Assert;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub hello {
    my $a_b_a = A::B::A->new;
    return $a_b_a->hello;
}

sub hello_b {
    require 'A/B/A.pm'; # to make sure this doesn't replace builtins.A with globals()['A']
    require 'A/B/B.pm';
    my $a_b_b = A::B::B->new;
    return $a_b_b->hello;
}

1;

