package TiedHash;
# Tied hash implementation for test issue_s154h
#
# This implementation is a simple hash but the keys are ordered in the order they were added
# code from https://metacpan.org/dist/Tie-IxHash/source/lib/Tie/IxHash.pm
#
# standard tie functions
#
 
sub TIEHASH {
  my($c) = shift;
  my($s) = [];
  $s->[0] = {};   # hashkey index
  $s->[1] = [];   # array of keys
  $s->[2] = [];   # array of data
  $s->[3] = 0;    # iter count
 
  bless $s, $c;
 
  $s->Push(@_) if @_;
 
  return $s;
}
 
#sub DESTROY {}           # costly if there's nothing to do
 
sub FETCH {
  my($s, $k) = (shift, shift);
  return exists( $s->[0]{$k} ) ? $s->[2][ $s->[0]{$k} ] : undef;
}
 
sub STORE {
  my($s, $k, $v) = (shift, shift, shift);
   
  if (exists $s->[0]{$k}) {
    my($i) = $s->[0]{$k};
    $s->[1][$i] = $k;
    $s->[2][$i] = $v;
    $s->[0]{$k} = $i;
  }
  else {
    push(@{$s->[1]}, $k);
    push(@{$s->[2]}, $v);
    $s->[0]{$k} = $#{$s->[1]};
  }
}
 
sub DELETE {
  my($s, $k) = (shift, shift);
 
  if (exists $s->[0]{$k}) {
    my($i) = $s->[0]{$k};
    for ($i+1..$#{$s->[1]}) {    # reset higher elt indexes
      $s->[0]{ $s->[1][$_] }--;    # timeconsuming, is there is better way?
    }
    if ( $i == $s->[3]-1 ) {
      $s->[3]--;
    }
    delete $s->[0]{$k};
    splice @{$s->[1]}, $i, 1;
    return (splice(@{$s->[2]}, $i, 1))[0];
  }
  return undef;
}
 
sub EXISTS {
  exists $_[0]->[0]{ $_[1] };
}
 
sub FIRSTKEY {
  $_[0][3] = 0;
  &NEXTKEY;
}
 
sub NEXTKEY {
  return $_[0][1][ $_[0][3]++ ] if ($_[0][3] <= $#{ $_[0][1] } );
  return undef;
}

#
# add pairs to end of indexed hash
# note that if a supplied key exists, it will not be reordered
#
sub Push {
  my($s) = shift;
  while (@_) {
    $s->STORE(shift, shift);
  }
  return scalar(@{$s->[1]});
}

1;
 
