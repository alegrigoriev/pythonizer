use Carp::Assert;

# Subroutine being tested
sub sub_with_output_parameter {
  assert(!($_[0]) || $_[0] eq 'different value', "Unexpected input value: $_[0]");
  $_[0] = 'expected value';
}

# Test function
sub test_output {
  my $output;

  # Call the subroutine being tested with different input values
  sub_with_output_parameter($output);
  assert($output eq 'expected value', "Unexpected output value for input 1: $output");

  $output = 'different value';
  sub_with_output_parameter($output);
  assert($output eq 'expected value', "Unexpected output value for input 2: $output");

  # Test the subroutine's return value
  $output = 'different value';
  assert(sub_with_output_parameter($output) eq 'expected value', "Unexpected return value");
  assert($output eq 'expected value', "Unexpected output value for input 3: $output");
}

# Run the test
test_output();
print "$0 - test passed!\n";
