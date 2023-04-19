package A::B::B;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub hello {
    return "Hello from A::B::B!";
}

1;
