# Tests for the oct and hex functions

use Carp::Assert;

$_ = "644";
assert(oct == 0644);
assert(oct "0777" == 0777);
assert(oct "0o12" == 012);
$val = "432";
assert(oct $val == 0432);
$h{k} = "01234567";
assert(oct $h{k} == 01234567);

assert(hex == 0x644);
assert(hex "fFe2" == 0xffe2);
assert(hex $val == 0x432);
assert(hex $h{k} == 0x1234567);
assert(175 == hex "0xAf");

print "$0 - test passed!\n";
