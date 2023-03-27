# issue s323 - Match object (_m) isn't set by a substitute whose value is being tested
use Carp::Assert;

sub match_dsn {
    $dsn =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i
		or '' =~ /()()/; # ensure $1 etc are empty if match fails
    $driver_attrib_spec = $2 || '';
}

$dsn = 'dbi:abc(in_parens):more';
match_dsn();
assert($driver_attrib_spec eq 'in_parens');

$dsn = '';
match_dsn();
assert($driver_attrib_spec eq '');

print "$0 - test passed\n";
