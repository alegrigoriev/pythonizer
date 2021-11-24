# Hash references should generate a get operation to mimic perl
use Carp::Assert;

%hash = (key=>'value');
assert($hash{key} eq 'value');
assert("$hash{key}" eq 'value');
$hash{key2} = 'value2';		# Make sure it doesn't mess up on lhs
assert($hash{key2} eq 'value2');
$notFound = $hash{notFound};
assert(!defined $notFound);
$notFoundInString = "$hash{notFound}";
assert(!$notFoundInString);
my $href = {rkey => 'rvalue'};	# Make sure it doesn't mess up other {...}
assert($href->{rkey} eq 'rvalue');
@arr = (0, 1, 2);	# Make sure it doesn't generate "get" for lists!
assert($arr[0] == 0 && $arr[1] == 1 && $arr[2] == 2);

print "$0 - test passed!\n";
