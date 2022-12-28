# Same as test_use_overload_fallbackn but with fallback False
package test_use_overload_fallbacko;
use overload '""' => \&as_string, 'fallback' => 0;

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
