# issue 128 - State variable initialized to a function argument generates bad code
use Carp::Assert;
use feature 'state';

sub times10 { $_[0]*10 }

sub banner {

	state $non_init;
	state $init_constant = 12;
	state $init_undef = undef;
	my $localvar = 4;
	state $from_local = $localvar;
	state $from_expr = times10($localvar)+2;
	state $from_arg = $_[0];
	state $in = 'in';
	state $from_fstring = "${in}x";		# issue 129

	$non_init++;
	$init_constant++;
	$init_undef++;
	$from_local++;
	$from_expr++;
	$from_arg++;
	$from_fstring .= 'x';
	$in .= 'a';

	return ($non_init, $init_constant, $init_undef, $from_local, $from_expr, $from_arg, $from_fstring, $in);
}

my ($ni, $ic, $iu, $fl, $fe, $fa, $ff, $in) = banner(100);
assert($ni == 1 && $ic == 13 && $iu == 1 && $fl == 5 && $fe == 43 && $fa == 101 && $ff eq 'inxx' && $in eq 'ina');
($ni, $ic, $iu, $fl, $fe, $fa, $ff, $in) = banner(0);
assert($ni == 2 && $ic == 14 && $iu == 2 && $fl == 6 && $fe == 44 && $fa == 102 && $ff eq 'inxxx' && $in eq 'inaa');

# From the documentation:

sub create_counter {
	return sub {state $x; return ++$x }
}

my $subref = create_counter;

assert(&$subref == 1);
assert(&$subref == 2);
assert(&$subref == 3);

my $sr2 = sub {
	my $local = 12;
	state $state = $local;

	return $state++;
};

assert(&{$sr2} == 12);
assert(&{$sr2} == 13);

print "$0 - test passed!\n";
