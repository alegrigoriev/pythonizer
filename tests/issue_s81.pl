# issue s81 - Regex \Z( being translated as $( special variable
use Carp::Assert;

my $string = "a";

if($string =~ /a\Z(?!\n)/) {
	;
} else {
	assert(0);
}

print "$0 - test passed!\n";
