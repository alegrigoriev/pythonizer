# Test modifying the loop counter in the loop

use Carp::Assert;

sub matching_paren
# Find matching paren, if found.
# Arg1 - the string to scan
# Arg2 - starting position for scan
# Arg3 - (optional) -- balance from whichto start (allows to skip opening paren)
{
my $str=$_[0];
my $scan_start=$_[1];
my $balance=(scalar(@_)>2) ? $_[2] : 0; # case where opening bracket is missing for some reason or was skipped.
   for( my $k=$scan_start; $k<length($str); $k++ ){
     my $s=substr($str,$k,1);
     if( $s eq '(' ){
        $balance++;
     }elsif( $s eq ')' ){
        $balance--;
        if( $balance==0  ){
           return $k;
        }
     }
  } # for
  return -1;
} # matching_paren

my $string = "abc((def)ghi)jkl";
my $result;
for(my $i = 0; $i < length($string); $i++) {
	if(($ch = substr($string, $i, 1)) eq '(') {
		$i = matching_paren($string, $i);
	} else {
		$result .= $ch;
	}
	my $j;
	for($j = 0; $j < 1; $j++) {
		;
	}
	{
	    $j = 14;	# Does NOT mod the loop ctr
	}
}
assert($result eq 'abcjkl');

print "$0 - test passed!\n";

