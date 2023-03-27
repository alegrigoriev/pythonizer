# issue s318 - eval {...} if... generates bad code
use Carp::Assert;
$ENV{DBI_PUREPERL} = 1;

do { $i = 1; $i++ } if        $ENV{DBI_PUREPERL} == 1;

eval { bootstrap DBI $XS_VERSION } if       $ENV{DBI_PUREPERL} == 1;
assert($@);
assert($i == 2);

print "$0 - test passed!\n";
