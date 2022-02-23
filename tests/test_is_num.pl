# test the idiom to see if a value is numeric
use Carp::Assert;

sub is_num
{
	return (scalar(@_) >= 1 && 
        length( do { no if $] >= 5.022, "feature", "bitwise"; no warnings "numeric"; $_[0] & "" } ) );
}

assert(is_num(0));
assert(is_num(1));
assert(is_num(2.5));
assert(is_num(-2.5));
assert(is_num(-4));
assert(!is_num('a'));
assert(!is_num('4'));
$i = 3;
assert(is_num($i));
$j = '4';
assert(!is_num($j));

print "$0 - test passed!\n";
