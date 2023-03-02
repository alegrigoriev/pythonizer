package TiedScalar;

sub TIESCALAR {
  my $class = shift;
  my $self = { value => shift };
  bless $self, $class;
}

sub FETCH {
  my $self = shift;
  $FETCH_CALLED++;
  #print "FETCH returns $self->{value}\n";
  return $self->{value};
}

sub STORE {
  my $self = shift;
  $STORE_CALLED++;
  #print "STORE($_[0])\n";
  $self->{value} = shift;
}

sub UNTIE {
    $UNTIE_CALLED++;
    #print "UNTIE\n";
}

1;

