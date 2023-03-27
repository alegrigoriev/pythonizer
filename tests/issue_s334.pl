# issue s334 - Bad code is generated for complex map operation
use strict;
use warnings;
use Carp::Assert;

sub line_numbered_code {
    my ($method, $method_code) = @_;

    assert(defined $method && $method ne '', 'Method name must be defined and non-empty');
    assert(defined $method_code && $method_code ne '', 'Method code must be defined and non-empty');

    my $l=0;
    my $line_numbered_code = "*$method code:\n".join("\n", map { ++$l.": $_" } split/\n/,$method_code);

    return $line_numbered_code;
}

# Test cases
my $test_method = 'test_method';
my $test_method_code = "sub test_method {\n\tprint \"Hello, World!\\n\";\n}\n";

# Test 1: Basic functionality
{
    my $expected_output = "*test_method code:\n1: sub test_method {\n2: \tprint \"Hello, World!\\n\";\n3: }";
    my $actual_output = line_numbered_code($test_method, $test_method_code);
    assert($expected_output eq $actual_output, "line_numbered_code should return line-numbered code, expected: $expected_output, actual: $actual_output");
}

# Test 2: Single line code
{
    my $single_line_code = "print \"Hello, World!\\n\";\n";
    my $expected_output = "*test_method code:\n1: print \"Hello, World!\\n\";";
    my $actual_output = line_numbered_code($test_method, $single_line_code);
    assert($expected_output eq $actual_output, 'line_numbered_code should handle single line code');
}

# Test 3: Empty lines and indentation
{
    my $indented_code = "sub indented_method {\n\n\tprint \"Indented!\\n\";\n}\n";
    my $expected_output = "*test_method code:\n1: sub indented_method {\n2: \n3: \tprint \"Indented!\\n\";\n4: }";
    my $actual_output = line_numbered_code($test_method, $indented_code);
    assert($expected_output eq $actual_output, 'line_numbered_code should handle empty lines and indentation');
}

# Test 4: Invalid input - empty method name
{
    my $invalid_method = '';
    eval {
        line_numbered_code($invalid_method, $test_method_code);
    };
    assert($@, 'line_numbered_code should fail with empty method name');
}

# Test 5: Invalid input - empty method code
{
    my $invalid_code = '';
    eval {
        line_numbered_code($test_method, $invalid_code);
    };
    assert($@, 'line_numbered_code should fail with empty method code');
}

print "$0 - test passed!\n";

