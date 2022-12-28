# Same as test_use_overload_fallbackm but without cmp operator
package test_use_overload_fallbackn;
use overload '""' => \&as_string, 'fallback' => 1;

sub new {
    my ($class, $value) = @_;
    my $self = {};
    bless $self, $class;
    $self->value($value);
    return $self;
}

sub value {
    my ($self, $value) = @_;
    if(defined $value) {
        $self->{value} = $value;
    }
    return $self->{value};
}

sub as_string {
    my $self = shift;

    return "" . $self->value;
}

1;
