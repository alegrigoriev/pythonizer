# issue s302 - Goatse idiom to count the # of matches generates bad code
use Carp::Assert;

my $sep = ';';
my %E = (key => 'a;b;c');

sub items {
    $self = shift;
    return 1 + scalar(() = $E{$$self} =~ /\Q$sep\E/g);
}

my $key = 'key';
my $actual = items(\$key);
my $expected = 3;
assert($actual == $expected, "Actual #items $actual != $expected");

print "$0 - test passed!\n";
