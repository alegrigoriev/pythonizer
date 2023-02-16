use strict;
use warnings;
use English;
use Carp::Assert;

# Test $PERL_VERSION
assert(defined $PERL_VERSION, "PERL_VERSION should be defined");
assert($^V eq $PERL_VERSION, "PERL_VERSION should be eq \$^V");
assert("$^V" eq "$PERL_VERSION", "PERL_VERSION should be eq \$^V in an interpolated string");

# Test $OSNAME
assert(defined $OSNAME, "OSNAME should be defined");

# Test $EVAL_ERROR
eval { die "An error occurred!" };
assert(defined $EVAL_ERROR, "EVAL_ERROR should be defined");
assert($EVAL_ERROR =~ /^An error occurred!/, "EVAL_ERROR should contain the error message");

# Test $OS_ERROR
sub test_os_error {

    # Test @ARG
    assert(scalar(@ARG) == 0);
    assert(!defined $ARG[0]);

    my $file = "nonexistent_file.txt";

    # Try to open the file
    open(my $fh, '<', $file) or do {
      assert(defined $OS_ERROR, "\$OS_ERROR should be defined");
      assert($OS_ERROR ne "", "\$OS_ERROR should contain a value");
      return;
    };

    assert(1, "Opened a non-existent file!");
}
test_os_error();

## Test $EXTENDED_OS_ERROR (not supported)
#my $extended_os_error = $EXTENDED_OS_ERROR;
#assert(defined $EXTENDED_OS_ERROR, "EXTENDED_OS_ERROR should be defined");

# Test $PROCESS_ID
assert(defined $PROCESS_ID, "PROCESS_ID should be defined");

# Test $PID
assert(defined $PID, "PID should be defined");
assert($PID == $PROCESS_ID, "PID should equal PROCESS_ID");

# Test $OSNAME
assert($OSNAME eq $^O, "OSNAME should be eq \$^O");

if($OSNAME ne 'MSWin32') {
    # Test $REAL_USER_ID
    assert(defined $REAL_USER_ID, "REAL_USER_ID should be defined");

    # Test $EFFECTIVE_USER_ID
    assert(defined $EFFECTIVE_USER_ID, "EFFECTIVE_USER_ID should be defined");

    # Test $REAL_GROUP_ID
    assert(defined $REAL_GROUP_ID, "REAL_GROUP_ID should be defined");

    # Test $EFFECTIVE_GROUP_ID
    assert(defined $EFFECTIVE_GROUP_ID, "EFFECTIVE_GROUP_ID should be defined");
}

# Test $PROGRAM_NAME
assert(defined $PROGRAM_NAME, "PROGRAM_NAME should be defined");

# Test $ARG0
assert(defined $0, "\$0 should be defined");
assert($0 eq $PROGRAM_NAME, "\$0 should equal PROGRAM_NAME");

# Test $ARGV
assert(scalar(@ARGV) == 0, "ARGV should be defined and have no elements");

# Test $EXECUTABLE_NAME
assert(defined $EXECUTABLE_NAME, "EXECUTABLE_NAME should be defined");

assert($EXECUTABLE_NAME =~ /perl|python/, "EXECUTABLE_NAME is not perl or python");

# Test $RS, $/, $INPUT_RECORD_SEPARATOR
assert(defined $RS, "RS should be defined");
assert($RS eq $/, "RS should be eq $/");
assert($INPUT_RECORD_SEPARATOR eq $/, "INPUT_RECORD_SEPARATOR should be eq $/");

# Test $OUTPUT_RECORD_SEPARATOR
{
    local $\ = "\n";
    assert(defined $OUTPUT_RECORD_SEPARATOR, "OUTPUT_RECORD_SEPARATOR should be defined");
    assert($ORS eq $OUTPUT_RECORD_SEPARATOR, "ORS should equal OUTPUT_RECORD_SEPARATOR");
    assert($\ eq $OUTPUT_RECORD_SEPARATOR, "ORS should equal OUTPUT_RECORD_SEPARATOR");
}

open(SOURCE, "<$PROGRAM_NAME") or die "Cannot open $PROGRAM_NAME";
my $line1 = <SOURCE>;
my $line2 = <SOURCE>;

# Test $INPUT_LINE_NUMBER, $NR, $.
assert(defined $INPUT_LINE_NUMBER, "INPUT_LINE_NUMBER should be defined");
assert($INPUT_LINE_NUMBER == 2, "INPUT_LINE_NUMBER should be 2");
assert($. == 2, "INPUT_LINE_NUMBER should be 2");
assert($NR == 2, "NR should be defined");

# Test SYSTEM_FD_MAX
assert($SYSTEM_FD_MAX == 2);

# Test BASETIME
assert(abs($BASETIME - $^T) <= 1);

# Test $MATCH, $PREMATCH, $POSTMATCH
my $test_string = "This is a test ";
if ($test_string =~ /(\w+)\s+(\w+)\s+(\w+)\s+(\w+)/) {
  assert(defined $1, "\$1 should be defined");
  assert($1 eq "This", "\$1 should equal 'This'");
  assert(defined $2, "\$2 should be defined");
  assert($2 eq "is", "\$2 should equal 'is'");
  assert(defined $3, "\$3 should be defined");
  assert($3 eq "a", "\$3 should equal 'a'");
  assert(defined $4, "\$4 should be defined");
  assert($4 eq "test", "\$4 should equal 'test'");
  assert($LAST_MATCH_START[0] == 0);
  assert($LAST_MATCH_START[1] == 0);
  assert($LAST_MATCH_START[2] == 5);
  assert($LAST_MATCH_START[3] == 8);
  assert($LAST_MATCH_START[4] == 10);
  assert($LAST_MATCH_END[0] == 14);
  assert($LAST_MATCH_END[1] == 4);
  assert($LAST_MATCH_END[2] == 7);
  assert($LAST_MATCH_END[3] == 9);
  assert($LAST_MATCH_END[4] == 14);
  assert($LAST_PAREN_MATCH eq 'test');
}

# Test $PREMATCH, $`
assert(defined $PREMATCH, "\$PREMATCH should be defined");
assert($PREMATCH eq "", "\$PREMATCH should be an empty string");
assert($` eq $PREMATCH, "\$PREMATCH should be eq \$`");

# Test $MATCH
assert(defined $MATCH, "\$MATCH should be defined");
assert($MATCH eq "This is a test", "\$MATCH should equal 'This is a test'");

# Test $POSTMATCH
assert(defined $POSTMATCH, "\$POSTMATCH should be defined");
assert($POSTMATCH eq " ", "\$POSTMATCH should be a single blank");

print "$PROGRAM_NAME - test passed!\n";
