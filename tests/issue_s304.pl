# issue s304 - If a file implements multiple packages with different tie operations, the wrong FETCH/STORE will be called
use Carp::Assert;

package Array;

sub TIEARRAY  { bless [], $_[0] }
sub FETCHSIZE { scalar @{$_[0]} }
sub STORESIZE { $#{$_[0]} = $_[1]-1 }
sub STORE     { $_[0]->[$_[1]] = $_[2] }
sub FETCH     { $_[0]->[$_[1]] }
sub CLEAR     { @{$_[0]} = () }
sub POP       { pop(@{$_[0]}) }
sub PUSH      { my $o = shift; push(@$o,@_) }
sub SHIFT     { shift(@{$_[0]}) }
sub UNSHIFT   { my $o = shift; unshift(@$o,@_) }
sub EXISTS    { exists $_[0]->[$_[1]] }
sub DELETE    { delete $_[0]->[$_[1]] }

package Hash;

sub TIEHASH  { bless {}, $_[0] }
sub STORE    { $_[0]->{$_[1]} = $_[2] }
sub FETCH    { $_[0]->{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub DELETE   { delete $_[0]->{$_[1]} }
sub CLEAR    { %{$_[0]} = () }
sub SCALAR   { scalar %{$_[0]} }

package main;
# Insert tests here
use Carp::Assert;

# Tie an array and test it
my @array;
tie(@array, 'Array');

$array[0] = 'foo';
assert($array[0] eq 'foo');  # Implicit FETCH and STORE

push(@array, 'bar');
assert($array[1] eq 'bar');  # Implicit FETCH and STORE

assert(scalar @array == 2);  # Implicit FETCHSIZE

# Tie a hash and test it
my %hash;
tie(%hash, 'Hash');

$hash{'key1'} = 'val1';
assert($hash{'key1'} eq 'val1');  # Implicit FETCH and STORE

$hash{'key2'} = 'val2';
assert($hash{'key2'} eq 'val2');  # Implicit FETCH and STORE

assert($hash{'key1'} eq 'val1');  # Implicit FETCH and STORE

assert(scalar keys %hash == 2);  # Implicit FIRSTKEY and NEXTKEY

print "$0 - test passed!\n";
