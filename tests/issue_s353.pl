# issue s353 - methods with multiple out parameters are not properly handled

package Date::Manip::Obj;
sub new { bless {}, shift };

package Date::Manip::Base;
our @ISA = qw(Date::Manip::Obj);

###############################################################################
# $self->_mod_add($N,$add,\$val,\$rem);
#   This calculates $val=$val+$add and forces $val to be in a certain
#   range.  This is useful for adding numbers for which only a certain
#   range is allowed (for example, minutes can be between 0 and 59 or
#   months can be between 1 and 12).  The absolute value of $N determines
#   the range and the sign of $N determines whether the range is 0 to N-1
#   (if N>0) or 1 to N (N<0).  $rem is adjusted to force $val into the
#   appropriate range.
#   Example:
#     To add 2 hours together (with the excess returned in days) use:
#       $self->_mod_add(-24,$h1,\$h,\$day);
#     To add 2 minutes together (with the excess returned in hours):
#       $self->_mod_add(60,$mn1,\$mn,\$hr);
sub _mod_add {
   my($self,$N,$add,$val,$rem)=@_;
   return  if ($N==0);
   $$val+=$add;
   if ($N<0) {
      # 1 to N
      $N = -$N;
      if ($$val>$N) {
         $$rem+= int(($$val-1)/$N);
         $$val = ($$val-1)%$N +1;
      } elsif ($$val<1) {
         $$rem-= int(-$$val/$N)+1;
         $$val = $N-(-$$val % $N);
      }

   } else {
      # 0 to N-1
      if ($$val>($N-1)) {
         $$rem+= int($$val/$N);
         $$val = $$val%$N;
      } elsif ($$val<0) {
         $$rem-= int(-($$val+1)/$N)+1;
         $$val = ($N-1)-(-($$val+1)%$N);
      }
   }

   return;
}

use Carp::Assert;

sub test_mod_add {
    my ($self, $N, $add, $val, $rem, $expected_val, $expected_rem) = @_;
    
    my $actual_val = $val;
    my $actual_rem = $rem;

    $self->_mod_add($N, $add, \$actual_val, \$actual_rem);

    assert($actual_val == $expected_val, "Expected value: $expected_val, Actual value: $actual_val");
    assert($actual_rem == $expected_rem, "Expected remainder: $expected_rem, Actual remainder: $actual_rem");
}

package main;

my $obj = Date::Manip::Base->new();


# Test case 1: Valid positive range (0 to N-1)
$obj->test_mod_add(60, 30, 15, 0, 45, 0);

# Test case 2: Valid negative range (1 to N)
$obj->test_mod_add(-24, 10, 5, 0, 15, 0);

# Test case 3: Add numbers within the range
$obj->test_mod_add(60, 20, 30, 0, 50, 0);

# Test case 4: Add numbers exceeding the range
$obj->test_mod_add(60, 50, 40, 0, 30, 1);
$obj->test_mod_add(-24, 20, 10, 0, 6, 1);

# Test case 5: Add negative numbers
$obj->test_mod_add(60, -20, 30, 0, 10, 0);
$obj->test_mod_add(-24, -10, 15, 0, 5, 0);

# Test case 6: Test edge cases
$obj->test_mod_add(60, 0, 59, 0, 59, 0); # No addition
$obj->test_mod_add(-24, 0, 24, 0, 24, 0); # No addition
$obj->test_mod_add(60, 60, 0, 0, 0, 1); # Exceed range by exactly N
$obj->test_mod_add(-24, 24, 1, 0, 1, 1); # Exceed range by exactly N

print "$0 - test passed!\n";
