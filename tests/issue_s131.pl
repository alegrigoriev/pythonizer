# issue s131 - Match capture variables are not set on a substitute
use Carp::Assert;

my $s = 'abc';
$s =~ s/([a-z])bc/xbc/;
assert($s eq 'xbc');
my $matched = $1;
assert($matched eq 'a');

$s = 'dbc';
if($s =~ s/([a-z])bc/xbc/) {
    assert($s eq 'xbc');
    assert($1 eq 'd');
} else {
    assert(0);
}

$s = 'ebc';
my $cnt = $s =~ s/([a-z])bc/xbc/;
assert($cnt == 1);
assert($1 eq 'e');
assert($s eq 'xbc');

# This one uses single quotes
my $s = 'fbc';
$s =~ s'([a-z])bc'$bc';
assert($s eq '$bc');
assert($1 eq 'f');

# This one has no capture group
my $s = 'abc';
$s =~ s/(?:[a-z])bc/xbc/;
assert($1 ne 'a');
assert($s eq 'xbc');

# Try one nested in a sub
sub testit {
    my $s = 'gbc';
    $s =~ s/([a-z])bc/xb$1/;
    assert($s eq 'xbg');
    assert($1 eq 'g');
}
testit();


print "$0 - test passed!\n";
