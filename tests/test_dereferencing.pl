use Carp::Assert;

# Subroutine being tested
sub check_dereferencing {
  my ($ref) = @_;

  # Check that the input value is a reference
  assert(ref($ref) eq 'ARRAY', "Input value is not an array reference: $ref");

  # Dereference the array and return the first element
  return ${$ref}[0];
}

# Test function
sub test_dereferencing {
  # Test the subroutine with a valid array reference
  assert(check_dereferencing([1, 2, 3]) == 1, "Unexpected output for input ([1, 2, 3])");

  # Test the subroutine with an invalid reference
  eval { check_dereferencing('abc') };
  assert($@ =~ /Input value is not an array reference:/, "Unexpected output for input ('abc')");
}

# Run the test
test_dereferencing();
print "$0 - test passed!\n";
