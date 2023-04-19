# issue s363 - Pattern style range operator no longer works if a simple string pattern is used
use strict;
use warnings;
no warnings 'experimental';

use Carp::Assert;

# The function to test
sub parse_static_block {
    my $input = shift;

    my @lines;
    for (split /\n/, $input) {
        if (/static:/ .. /^\s$/) {          # Line causing the issue
            push @lines, $_;
        }
    }

    return \@lines;
}

# We don't yet handle this case!
#sub parse_static_block2 {
#    my $input = shift;
#
#    my @lines;
#    for my $line (split /\n/, $input) {
#        if ($line =~ /static:/ .. $line =~ /^\s$/i) {  # Line causing the issue
#            push @lines, $line;
#        }
#    }
#
#    return \@lines;
#}

# Test data
my $test_data = <<'EOF';
some random text
static: Start of static block
  line with whitespace
    line with more whitespace
 
another line
EOF

# Expected output
my $expected_output = [
    "static: Start of static block",
    "  line with whitespace",
    "    line with more whitespace",
    " "
];

# Run the test
my $parsed_output = parse_static_block($test_data);
assert($parsed_output ~~ $expected_output, 'Parsing static block works as expected');

#$parsed_output = parse_static_block2($test_data);
#assert($parsed_output ~~ $expected_output, 'Parsing static block 2 works as expected');

print "$0 - test passed!\n";
