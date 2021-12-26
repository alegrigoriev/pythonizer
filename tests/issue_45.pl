# issue 45: simple constant definition sub doesn't generate proper code
use Carp::Assert;

sub false { 0 }
assert(!false);
sub true { 1; }
assert(true);
sub QUIET { 1 }         # Be quiet!
assert(0) if(!QUIET);
sub PI ()           { 4 * atan2 1, 1 }
assert(int(PI) == 3);
sub thirteen {
	my $th = 13;
	$th;
}
assert(thirteen == 13);
sub fourtytwo {
	$v42 = 42;
}
assert(fourtytwo() == 42);
sub fourtythree { my $v43 = 43; }
assert(fourtythree() == 43);
sub fourtyfour { $v44 = 44 }
assert(fourtyfour() == 44);
assert($v44 == 44);
sub iffy {
	my $var = 12;
	if($var == 12) {
		$var = 13;
	} else {
		$var = 14;
	}
}
#assert(iffy == 13);

sub preadd {
    my $arg = shift;
    ++$arg;
}

assert(preadd(1) == 2);

sub presub {
    my $arg = shift;
    --$arg;
}
assert(presub(1) == 0);

sub postadd {
    my $arg = shift;
    $arg++;
}

assert(postadd(1) == 1);

sub postsub {
    my $arg = $_[0];
    $arg--;
}
assert(postsub(1) == 1);

print "$0 - test passed!\n";
