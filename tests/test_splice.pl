# test splice using examples from the documentation
use Carp::Assert;

my @a = (1,2,3);
my @b = (1,2,3);

my $x = 4;
my $y = 5;

push(@a,$x,$y);
my @c = splice(@b,@b,0,$x,$y);

assert(join('',@a) eq '12345');
assert(join('',@b) eq '12345');
assert(!@c);

pop(@a);
my $c = splice(@b,-1);	# Scalar context
assert(join('',@a) eq '1234');
assert(join('',@b) eq '1234');
assert($c eq '5');

shift(@a);
@c = splice(@b,0,1);
assert(join('',@a) eq '234');
assert(join('',@b) eq '234');
assert(join('',@c) eq '1');

unshift(@a,$x,$y);
@c = splice(@b,0,0,$x,$y);
assert(join('',@a) eq '45234');
assert(join('',@b) eq '45234');
assert(!@c);

my $i = 2;
$a[$i] = $y;
@c = splice(@b,$i,1,$y);
assert(join('',@a) eq '45534');
assert(join('',@b) eq '45534');
assert(join('',@c) eq '2');

sub nary_test {
	my @result = ();
	my $n = shift;
	while(my @next_n = splice @_, 0, $n) {
	    push @result, join q{--}, @next_n;
        }
	return @result;
}

assert(join(' ', nary_test(3, qw(a b c d e f g h))) eq 'a--b--c d--e--f g--h');

print "$0 - test passed!\n";
		


