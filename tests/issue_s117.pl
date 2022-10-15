# issue s117 - referencing an undefined variable in an interpolated string should give an empty string, not 'None'
# from diffdata.pl
use Carp::Assert;

$mtsportcard = $empty_hash{key};
$CONSTANT = 'constant';
$INTEGER = 1;
@array = (1,2);

assert("$new_hash{k1}{j2}," eq ',');	# this should already work
assert("$mtsportcard," eq ',');
assert("$CONSTANT," eq 'constant,');
assert("$INTEGER," eq '1,');
assert("$array[0]," eq '1,');

print "$0 - test passed\n";
