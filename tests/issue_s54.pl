# issue s54: Implement UNIVERSAL::isa
use Carp::Assert;
use Math::Complex;
use IO::File;

sub myfunc
{
	my $arg = shift;
	my $what = shift;

	assert(UNIVERSAL::isa($arg, $what));
}

my $scalar = 1;
myfunc(\$scalar, 'SCALAR');
$scalar = 1.0;
myfunc(\$scalar, 'SCALAR');
undef $scalar;
myfunc(\$scalar, 'SCALAR');
$scalar = 'str';
myfunc(\$scalar, 'SCALAR');
myfunc([1, 2], 'ARRAY');
myfunc({key=>'value'}, 'HASH');

my $io = IO::File->new();
assert($io->isa('IO::Handle'));
$z = Math::Complex->make(5, 6);
assert($z->isa('Math::Complex'));

print "$0 - test passed!\n";
