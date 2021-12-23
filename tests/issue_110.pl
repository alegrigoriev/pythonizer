# issue 110: A return statement with a || expression generates bad code

use Carp::Assert;

sub IS_A_NUMBER {
   return ($_[0] =~ /^(\+|-)?([0-9]|\.)+$/) || 0 ;
}

#sub IS_A_NUMBER_nr {
#($_[0] =~ /^(\+|-)?([0-9]|\.)+$/) || 0 ;
#}

assert(IS_A_NUMBER('42'));
assert(IS_A_NUMBER('0'));
assert(!IS_A_NUMBER('oops'));

#assert(IS_A_NUMBER_nr('42'));
#assert(IS_A_NUMBER_nr('0'));
#assert(!IS_A_NUMBER_nr('oops'));

print "$0 - test passed!\n";
