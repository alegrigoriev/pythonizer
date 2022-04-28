package test_overload;

sub new
{
	my $class = shift;
	my $value = shift;

	return bless {value=>$value};
}

use overload '+'=>\&times, '""'=>\&stringify, '=='=>\&equals, '<=>'=>\&spaceship;

sub times
{
	my $self = shift;
	my $other = shift;

	return $self->new($self->{value} * $other->{value});
}

sub stringify
{
	$self = shift;
	return "" . $self->{value};
}

sub equals
{
	$self = shift;
	$other = shift;
	if(ref $other) {
		return $self->{value} == $other->{value};
	}
	return $self->{value} == $other;
}

sub spaceship
{
	$self = shift;
	$other = shift;
	if(ref $other) {
		return $self->{value} <=> $other->{value};
	}
	return $self->{value} <=> $other;
}
1;
