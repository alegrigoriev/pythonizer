#!/usr/bin/perl
# issue s345 - Diamond operator with python keyword as file handle generates bad code
# This is the expected comment line

use strict;
use warnings;
use IO::File;
use Carp::Assert;

# Prepare the input file
my $input_file = $0;

# Open the input file
my $in = new IO::File;
if (! $in->open($input_file)) {
    die "Unable to open $input_file";
}

# Read the content
my @in = <$in>;

# Close the file
$in->close();

# Check for the presence of a specific comment line
my $expected_comment = "# This is the expected comment line\n";
my $comment_found = 0;

for my $line (@in) {
    if ($line eq $expected_comment) {
        $comment_found = 1;
        last;
    }
}

# Test case
assert($comment_found, "The expected comment line is present in the input file");

print "$0 - test passed!\n";
