# issue s77 - push containing a || doesn't work
use Carp::Assert;
undef $a;
push(@result, $a || '');
assert(scalar(@result) == 1);
assert($result[0] eq '');

if(0) {
	push(@result,$self->script({@satts}, $code || ''));
}
print "$0 - test passed!\n";
