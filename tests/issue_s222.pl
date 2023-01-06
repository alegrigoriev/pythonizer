# issue s222 - $#$order gives an incorrect value if $order is a my variable in a sub
# pragma pythonizer -M
use Carp::Assert;
sub _rearrange_params {
    my($order,@param) = @_;
    my @result;
    $#result = $#$order;    #preextend
    assert(scalar(@result) == scalar(@{$order}));
    assert($#result == $#$order);
    assert($#result == $#{$order});
    return scalar(@result);
}
assert(_rearrange_params([1, 2]) == 2);

$order = [3,4,5];

sub _rearrange_params2 {
    my @result;
    $#result = $#$order;    #preextend
    assert(scalar(@result) == scalar(@{$order}));
    assert($#result == $#$order);
    return scalar(@result);
}
assert(_rearrange_params2() == 3);
print "$0 - test passed!\n";
