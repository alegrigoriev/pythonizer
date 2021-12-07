# issue 85: '}' being recognized as end-of-block within an expression
use Carp::Assert;
$j = $k = $m = 1;
$i = $j + 
     $k
     * 2 +
     $m;
assert($i == 4);
$region = 'r';
%ratiostd = (r=>undef);
%ratiocount = (r=>2);
%ratiosquares = (r=>4);
%ratiosum = (r=>0);

      $ratiostd{$region} = sqrt(($ratiocount{$region}*$ratiosquares{$region}
         -$ratiosum{$region}*$ratiosum{$region})
         / ($ratiocount{$region}*($ratiocount{$region}-1)));

assert($ratiostd{$region} == 2);

# Need to recognize EOL on the next line:
sub abc { $i = 12 }

assert(abc() == 12);
assert($i == 12);

print "$0 - test passed!\n";
