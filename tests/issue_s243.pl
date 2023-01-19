# issue s243 - eval with nested sub generates bad python code with syntax error
package B;
use Carp::Assert;

sub svref_2object {
    my $arg = shift;
    return bless $arg, 'B';
}

sub isa {
    my ($this, $name) = @_;
    return $name eq 'B::HV';
}
eval q|
*UNIVERSAL::TO_JSON = sub {
    my $b_obj = B::svref_2object( $_[0] );
    1 or return 2;      # Check it's not doing an eval_return!
    return    $b_obj->isa('B::HV') ? { %{ $_[0] } }
            : $b_obj->isa('B::AV') ? [ @{ $_[0] } ]
            : undef
            ;
};
|;

my $hashref = {key=>'value'};

my $hashr = UNIVERSAL::TO_JSON($hashref);

assert($hashr->{key} eq 'value');

# Try an eval (w/o brackets) in a sub to see the difference
sub try_eval {
    my $seven = eval q(return 7);
    assert($seven == 7);
}
try_eval();

print "$0 - test passed!\n";
