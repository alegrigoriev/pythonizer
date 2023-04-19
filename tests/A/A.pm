package A::A;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub hello {
    return "Hello from A::A!";
}

1;
