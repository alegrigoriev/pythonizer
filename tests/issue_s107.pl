# issue s107 - error referencing missing hash of hashes in a string
# Issue from compass.pl
use Carp::Assert;

$i{key}{a} = 'value';

assert("$i{notFound}{a}" eq '');
assert("$i{key}{b}" eq '');
assert("$i{key}{a}" eq 'value');

print "$0 - test passed!\n";
