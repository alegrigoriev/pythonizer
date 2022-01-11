# Issue variable variable name
# Code from Getopt::STD
use Carp::Assert;

@ARGV = ('-a', '-b');
$rest = 'b';
${'first'} = 'a';
@EXPORT = ();
	    
no strict 'refs';
${"opt_$first"} = 1;
push( @EXPORT, "\$opt_$first" );

if ($rest ne '') {
    $ARGV[0] = "-$rest";
    my $i = 1;
    $ARGV[$i] = "-c";
}

assert($opt_a == 1);
assert($ARGV[0] eq '-b');
assert($ARGV[1] eq '-c');
assert($EXPORT[0] eq '$opt_a');

print "$0 - test passed!\n";
