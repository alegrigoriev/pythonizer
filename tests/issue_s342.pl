# issue s342 - %+ hash is not available
use Carp::Assert;
use Storable qw(dclone);

# Perform a regular expression match with named capture groups 
'foobar' =~ /(?<foo>foo)(?<bar>bar)/; 

# Initialize %+ with the named capture groups from the last match 
my %tmp = %{ dclone(\%+) }; 

# Assert that the %+ hash contains the expected values 
assert( $tmp{foo} eq 'foo' );
assert( $tmp{bar} eq 'bar' );
$tmp{zap} = 'zap';
assert($tmp{zap} eq 'zap');

assert(!exists $+{zap});

print "$0 - test passed\n";
