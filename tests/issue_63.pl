use Carp::Assert;
@arr = (1, 2, 3, 4);
(undef, undef, undef, $i) = @arr;
assert($i eq 4);
print "$0 - test passed!\n";
