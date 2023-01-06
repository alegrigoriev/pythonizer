# tests for File::Copy, from the documentation
# pragma pythonizer -s
use strict;
use warnings;
use File::Copy;
use File::Path;
use Carp::Assert;

# Create the input directory
mkdir 'input' or die "Could not create input directory: $!";

# Create the input file
open(my $fh, '>', 'input/file.txt') or die "Could not create input file: $!";
print $fh "This is the input file";
close $fh;

# Create the output directory
mkdir 'output' or die "Could not create output directory: $!";

# Test copying a file from the current directory to another location
# Check that the File::Copy function returns a true value
assert (
   copy('input/file.txt', 'output/file.txt') == 1
);

# Check that the contents of the input and output files are the same
open(my $in_fh, '<', 'input/file.txt') or die "Could not read input file: $!";


open(my $out_fh, '<', 'output/file.txt') or die "Could not read output file: $!";


my $in_contents = do { local $/; <$in_fh> };


my $out_contents = do { local $/; <$out_fh> };

close $in_fh;
close $out_fh;

assert (
   $in_contents eq $out_contents
);

# Test copying a file from the current directory to a non-existent directory
assert (
   copy('input/file.txt', 'output/non-existent/dir/file.txt') == 0
);

# Test copying a file that does not exist in the current directory
assert (
   copy('non-existent/file.txt', 'output/file.txt') == 0
);

# Test copying a file with a file name that already exists in the destination directory
assert (
   copy('input/file.txt', 'output/file.txt') == 1 #MODIFIED BOOL -- should this be 0 or 1 bc line 21 is 1
);

# # Test copying a file and overwriting the existing file in the destination directory
assert (
   #copy('input/file.txt', 'output/file.txt', { overwrite => 1 }) == 1
   # 3rd parameter is buffer size
   copy('input/file.txt', 'output/file.txt', 16) == 1
);

# Clean up after ourselves
END {
    unlink 'input/file.txt';
    unlink 'output/file.txt';
    rmtree('input');
    rmtree('output');
}
print "$0 - test passed!\n";
