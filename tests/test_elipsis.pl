# test elipsis statement

use Carp::Assert;

if(0) {
    ...
} else {
    $cnt++;
}
assert($cnt == 1);

eval {
    ...
};
assert($@ =~ /Unimplemented/);

print "$0 - test passed!\n";

