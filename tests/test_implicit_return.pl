# test implicit function return value of last expression evaluated
use Carp::Assert;

sub test1
# Returns it's arg, as long as it's in the range 1-5, else returns -1
{
	my $a = $_[0];

	if($a == 0) {
		0;			# Make sure we don't insert a return here!
	}
	if($a == -1) {
		;			# Make sure we don't insert a return here either!
	}
	if($a == 1) {
		1;			# level 2
	} elsif($a == 5) {
		if($a == 5) {
			-1;		# no return here
		} else {
			-1;		# none here either
		}
		4 + 1;			# level 2
	} else {
		if($a == 2) {
			1;
			2;		# level 3
		} elsif($a == 3) {
			1;
			2;
			3;		# level 3
		} else {
			if($a == 4) {
				4;	# level 4
			} else {
				-1;	# level 2, 3, 4
			}
		}
	}
}

for(my $i=1; $i <= 5; $i++) {
	assert(test1($i) == $i);
}
assert(test1(0) == -1);

my $tot = 0;
sub test2
{
	my $a = $_[0];

	if($a == 1) {
		1;
	} elsif($a == 4) {
		4;
	} else {
		if($a == 2) {
			1;
			2;
		} elsif($a == 3) {
			1;
			2;
			3;
		}
	}
	$tot++;			# Makes sure we don't insert return statements above!
	10;			# Always returns 10
}
for(my $i=1; $i <= 4; $i++) {
	assert(test2($i) == 10);
}
assert(test2(0) == 10);
assert($tot == 5);

sub test3
# Returns it's arg, as long as it's in the range 1-4, else returns -1
# Same as test1, but using an inner anonymous sub
{
	my $a = $_[0];

	my $inner = sub {
		if($a == 1) {
			1;
		} elsif($a == 4) {
			4;
		} else {
			if($a == 2) {
				1;
				2;
			} elsif($a == 3) {
				1;
				2;
				3;
			} else {
				-1;
			}
		}
	};

	return &$inner();
}

for(my $i=1; $i <= 4; $i++) {
	assert(test3($i) == $i);
}
assert(test3(0) == -1);

sub test4
# Here we have a lower if, which prevents us from inserting returns in the upper if
{
	my $a = $_[0];

	if($a == 1) {
		1;
	} elsif($a == 4) {
		4;
	} else {
		if($a == 2) {
			1;
			2;
		} elsif($a == 3) {
			1;
			2;
			3;
		}
	}
	if(1) {
		12;			# Always returns 12
	}
}
for(my $i=1; $i <= 4; $i++) {
	assert(test4($i) == 12);
}
assert(test4(0) == 12);

# Test case from diffdata.pl:

sub bynumempty
{
   if ($a eq "" and $b eq "")
   {
      return 0;
   }
   elsif ($a eq "")
   {
      return -1;
   }
   elsif ($b eq "")
   {
      return 1;
   }
   else
   {
      $a <=> $b;
   }
}

$a = $b = '';
assert(bynumempty() == 0);
$a = 'a'; $b = '';
assert(bynumempty() == 1);
$a = ''; $b = 'b';
assert(bynumempty() == -1);
$a = 1; $b = 2;
assert(bynumempty() < 0);
$b = 1;
assert(bynumempty() == 0);
$a = '2'; $b = '1';
assert(bynumempty() > 0);

print "$0 - test passed!\n";
