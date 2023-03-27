# Part of issue_s331
package MyNumber;

use strict;
use warnings;
use overload
    '+'  => 'add',
    '-'  => 'subtract',
    '++' => 'increment',
    '--' => 'decrement';

sub new {
    my ($class, $value) = @_;
    my $self = { value => $value };
    bless $self, $class;
}

sub add {
    my ($self, $other) = @_;
    my $other_value = ref($other) ? $other->{value} : $other;
    return MyNumber->new($self->{value} + $other_value);
}

sub subtract {
    my ($self, $other) = @_;
    my $other_value = ref($other) ? $other->{value} : $other;
    return MyNumber->new($self->{value} - $other_value);
}

sub increment {
    my $self = shift;
    $self->{value}++;
    return $self;
}

sub decrement {
    my $self = shift;
    $self->{value}--;
    return $self;
}

sub value {
    my $self = shift;
    return $self->{value};
}

1;

