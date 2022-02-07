# issue 86 - Translating a line with multiple bash-style "and"s / "or"s generates hanging indents

use Carp::Assert;

$r1 = 'r1';

($ec1 = $ar2equivc{$r1})
       || ($ec1 = $ar2equivc{"$r1:stub"})
       || ($ec1 = $r1);

assert($ec1 eq $r1);

print "$0 - test passed!\n";
