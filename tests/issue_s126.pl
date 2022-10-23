# issue s126 - naming variables starting with _ can conflict with pythonizer function names
# pragma pythonizer -P
use Carp::Assert;

my $_str = 'string';
assert($_str == 'string');
my $zero = 0;
assert($zero eq '0');
my $_int = 42;
assert($_int ==  42);
my $_int_ = 43;
assert($_int_ ==  43);
my $flt = 0.0;
my @arr = (0, 1);
assert($arr[$flt] == 0);
my $_num = 44;
assert($_num == 44);
assert($_str == 0);
my $_perl_print = 99;
assert($_perl_print == 99);
my $_END = 'e';
assert($_END eq 'e');

END {
	print "$0 - test passed!\n";
}

