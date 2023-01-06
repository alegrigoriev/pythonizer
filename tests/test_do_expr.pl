use Carp::Assert;
# pragma pythonizer -M

# Test that "do EXPR" executes code contained in a file
$file = "./testdo/test_script.pl";
assert(do $file);

# Test that "do EXPR" returns the value of the last expression evaluated
$result = do "./testdo/test_script.pl";
#assert($result == 10);
assert($result);            # we don't preserve the return value

# Test that "do EXPR" correctly handles syntax errors
$py = ($0 =~ /\.py$/);
if($py) {
    # Ensure it really contains a syntax error
    open(SYNTAX, '>>', './testdo/test_script_syntax_error.pl');
    print SYNTAX "print(\"Hello, world\n";
    close(SYNTAX);
}
do "./testdo/test_script_syntax_error.pl";
if ($@) {
  # Syntax error occurred
  assert(1);
} else {
  assert(0, "Expected syntax error but none occurred");
}

# Test that "do EXPR" correctly handles runtime errors
do "./testdo/test_script_runtime_error.pl";
if ($@) {
  # Runtime error occurred
  assert(1);
} else {
  assert(0, "Expected runtime error but none occurred");
}

# Test that "do EXPR" can execute code stored in a file specified by a variable
$file = "./testdo/test_script.pl";
assert(do $file);

# Test that "do EXPR" correctly handles the case where the file does not exist
assert(!defined (do "nonexistent_file.pl"));
if ($!) {
  # File does not exist
  assert(1);
} else {
  assert(0, "Expected file not found error but none occurred");
}

# Test that "do EXPR" runs the file each time it is called and not just once
$count = 0;
$file = "./testdo/counter_script.pl";
do $file;
#$count++;
assert($count == 1);
do $file;
#$count++;
assert($count == 2);
do $file if $count == 2;
assert($count == 3);
# Test '..' in path
assert(do "../tests/testdo/" . "counter_script.pl");
assert($count == 4);

do { $count++ } while $count < 6;
assert($count == 6);

print "$0 - test passed!\n";
## test_script.pl
## Returns the value 10
#10;
#
## test_script_syntax_error.pl
## Contains a syntax error (missing closing quote)
#print "Hello, world!
#
## test_script_runtime_error.pl
## Contains a runtime error (division by zero)
#$x = 10 / 0;
#
## counter_script.pl
## Increments a global counter variable each time it is run
#$count++;
