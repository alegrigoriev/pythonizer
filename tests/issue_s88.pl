# issue s88 - anonymous hashes containing a single array generate incorrect code
use Carp::Assert;

my @arr = ('a', 1, 'b', 2);

my $hashref = {@arr};

assert($hashref->{a} == 1);
assert($hashref->{b} == 2);

sub sub1
{
    my $arg = $_[0];

    assert($arg->{a} == 1);
    assert($arg->{b} == 2);
}

sub sub2
{
    assert($_[0] == 1);
    my $arg = $_[1];

    assert($arg->{a} == 1);
    assert($arg->{b} == 2);
}

sub1({@arr});
sub2(1, {@arr});

print "$0 - test passed!\n";
