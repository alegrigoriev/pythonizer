# issue s154: implement tie
# This tests tied hashes
use warnings ;
use strict ;
use lib '.';
use TiedHash ;
use Carp::Assert;

my %h ;

tie %h, "TiedHash"
    or die "Cannot tie hash" ;

assert(ref \%h eq 'HASH');

# Add a key/value pair to the file
$h{'Wall'} = 'Larry' ;
$h{'Smith'} = 'John' ;
$h{'mouse'} = 'mickey' ;
$h{'duck'}  = 'donald' ;

# Delete
delete $h{"duck"} ;

# Cycle through the keys printing them in order.
# Note it is not necessary to sort the keys as
# the TiedHash will have kept them in order automatically.
my @keys = ('Wall', 'Smith', 'mouse');
my @values = ('Larry', 'John', 'mickey');
my $i = 0;
my $tot = 0;
foreach (keys %h)
  { 
      assert($_ eq $keys[$i]);
      assert($h{$_} eq $values[$i++]);
      $tot++;
  }
assert($tot == 3);

$i = 0;
$tot = 0;
my ($key, $val);
while(($key, $val) = each %h) {
      assert($key eq $keys[$i]);
      assert($val eq $values[$i++]);
      $tot++;
}
assert($tot == 3);

untie %h ;

assert(scalar(%h) == 0);

print "$0 - test passed!\n";
