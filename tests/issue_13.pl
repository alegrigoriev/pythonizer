# issue 13: Bare Words are not handled properly

use Carp::Assert;

@regions=(AP,EMEA,LA,Canada);
%hash1=(This=>"this", That=>"that", Two=>2);
$options{OPTION}=1;

assert(@regions == 4);
assert($regions[0] eq 'AP');
assert($regions[1] eq 'EMEA');
assert($regions[2] eq 'LA');
assert($regions[3] eq 'Canada');

assert($hash1{This} eq 'this');
assert($hash1{That} eq 'that');
assert($hash1{Two} == 2);

assert($options{OPTION} == 1);

print "$0 - test passed!\n";
