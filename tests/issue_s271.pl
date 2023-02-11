# issue s271 - Using => instead of , to separate function/sub arguments can generate bad code
use Carp::Assert;

sub add_numbers {
  my ($a, $b) = @_;
  
  assert($a =~ /^\d+$/, "First argument is not a number") if defined $a;
  assert($b =~ /^\d+$/, "Second argument is not a number") if defined $b;
  
  return $a + $b;
}

# Test the add_numbers function
assert(add_numbers(5 => 6) == 11, "Test 1 failed");
assert(add_numbers(10 => 5) == 15, "Test 2 failed");
assert(add_numbers(0, 0) == 0, "Test 3 failed");

sub calculate_average {
  my %params = @_;
  
  assert(exists $params{numbers}, "Numbers are missing from the parameters") if %params;
  assert(scalar @{$params{numbers}} > 0, "Numbers list is empty") if @{$params{numbers}};
  
  my $sum = 0;
  foreach my $number (@{$params{numbers}}) {
    assert($number =~ /^\d+$/, "Not a number in the list") if defined $number;
    $sum += $number;
  }
  
  return $sum / scalar @{$params{numbers}};
}

# Test the calculate_average function
assert(calculate_average(numbers => [1, 2, 3, 4, 5]) == 3, "Test 1 failed");
assert(calculate_average(numbers => [10, 20, 30, 40]) == 25, "Test 2 failed");
assert(calculate_average(numbers => [100, 200, 300]) == 200, "Test 3 failed");

# Test a built-in function with multiple arguments
assert(substr("Hello, World!", 7, 5) eq "World", "Test 1 failed");
assert(substr("Hello, World!" => 7, 5) eq "World", "Test 1 failed");
assert(substr("Hello, World!" => 0 => 5) eq "Hello", "Test 2 failed");
assert(substr("Hello, World!", -6 => 5) eq "World", "Test 3 failed");

print "$0 - test passed!\n";
