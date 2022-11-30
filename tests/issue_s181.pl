# issue s181 - do statement in complex ? : chain of operations generates bad code
# This turned out to be caused by another fix but we will keep this as a test case anyway
use Carp::Assert;

# Start with a simple one:

my $type = '%';
$result = $type eq '%' ? 4 :
    do {require Carp; Carp::croak('Simple test failed!') };
assert($result == 4);

my %map = ('&'=>1, '$'=>2, '@'=>3, '%'=>4, '*'=>5);
sub check_result
{
    my ($result, $type) = @_;
    assert($map{$type} == $result);
}
foreach $type (keys %map) {
      check_result($result =
        $type eq '&' ? 1 :
        $type eq '$' ? 2 :
        $type eq '@' ? 3 :
        $type eq '%' ? 4 :
        $type eq '*' ?  5 :
        do { require Carp; Carp::croak("Bad type") },
        $type);
      assert($map{$type} == $result);
}

print "$0 - test passed\n";
