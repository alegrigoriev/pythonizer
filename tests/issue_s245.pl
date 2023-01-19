# issue 245: If the Pythonizer input file has no file extension, the output filename is not correct 
use strict;
use warnings;
use File::Path;
use Carp::Assert;

sub extension {
    my $input = shift;
    my $output = $input;
    my @inputparts = split /\./, $input;
    my @outputparts = split /\./, $output;
    if (@inputparts > 1) { 
        assert (@outputparts > 1)
    } else {
        assert (@outputparts <= 1)
    }
    return $output;
}

# Test example.txt file extention
my $input = "example.txt";
my $output=extension($input);
assert($output eq $input);

# Test example no extention file extention
$input = "example";
$output=extension($input);
assert($output eq $input);

# Test example mistype, extra character file extention
$input = "example..";
$output=extension($input);
assert($output eq $input);

#Test case for multiple dots in the input file
$input = "example.file.txt";
$output=extension($input);
assert($output eq $input);

#Test case for uppercase extension
$input = "example.TXT";
$output=extension($input);
assert($output eq $input);

#Test case for special characters in the file name
$input = "example#%^.txt";
$output=extension($input);
assert($output eq $input);

#Test case for no extension in the input file name
$input = "example#%^";
$output=extension($input);
assert($output eq $input);

print "$0 - test passed!\n";