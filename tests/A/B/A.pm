package A::B::A;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub hello {
    return "Hello from A::B::A!";
}

1;

