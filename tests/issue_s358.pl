# issue s358 - bad code generated for ' 'x$pad operation
use Carp::Assert;

sub printit {
   my ($val, $width, $pad) = @_;
   my $s = $val < 0 ? '-' : '';
   $val = abs($val);
   if ($width) {
      if      ($pad eq ">") {
         $val = "$s$val";
         my $pad = ($width > length($val) ? $width - length($val) : 0);
         $val .= ' 'x$pad;

      } elsif ($pad eq "<") {
         $val = "$s$val";
         my $pad = ($width > length($val) ? $width - length($val) : 0);
         $val = ' 'x$pad . $val;

      } else {
         my $pad = ($width > length($val)-length($s) ?
                    $width - length($val) - length($s): 0);
         $val = $s . '0'x$pad . $val;
      }
   } else {
      $val = "$s$val";
   }

   return $val;
}

use strict;
use warnings;
use Carp::Assert;

# Test Case 1: Test with positive numbers
{
    my $result = printit(42, 5, '>');
    assert($result eq '42   ', "Test Case 1: positive number, right padding: <$result>");
}

# Test Case 2: Test with negative numbers
{
    my $result = printit(-42, 6, '>');
    assert($result eq '-42   ', "Test Case 2: negative number, right padding: <$result>");
}

# Test Case 3: Test with positive numbers and left padding
{
    my $result = printit(42, 5, '<');
    assert($result eq '   42', "Test Case 3: positive number, left padding: <$result>");
}

# Test Case 4: Test with negative numbers and left padding
{
    my $result = printit(-42, 6, '<');
    assert($result eq '   -42', "Test Case 4: negative number, left padding: <$result>");
}

# Test Case 5: Test with positive numbers and zero padding
{
    my $result = printit(42, 5, '0');
    assert($result eq '00042', "Test Case 5: positive number, zero padding: <$result>");
}

# Test Case 6: Test with negative numbers and zero padding
{
    my $result = printit(-42, 6, '0');
    assert($result eq '-00042', "Test Case 6: negative number, zero padding: <$result>");
}

# Test Case 7: Test with width equal to the length of the value
{
    my $result = printit(12345, 5, '0');
    assert($result eq '12345', "Test Case 7: width equal to length of value: <$result>");
}

# Test Case 8: Test with width less than the length of the value
{
    my $result = printit(12345, 4, '0');
    assert($result eq '12345', "Test Case 8: width less than length of value: <$result>");
}

# Test Case 9: Test without specifying width and pad
{
    my $result = printit(42);
    assert($result eq '42', "Test Case 9: no width and pad specified: <$result>");
}

# Test Case 10: Test with invalid padding character
{
    my $result = printit(42, 5, '*');
    assert($result eq '00042', "Test Case 10: invalid padding character: <$result>");
}

print "$0 - test passed.\n";

