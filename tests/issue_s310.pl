# issue s310 - LINE XXXX [main-W6814]: Update to $_ alias of foreach items will not modify list items
no warnings 'experimental';
use Carp::Assert;

$slice = [1,2,3];
for (@$slice) { $_-- }

assert($slice ~~ [0,1,2]);

print "$0 - test passed!\n";
