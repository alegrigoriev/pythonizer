# issue s355 - undef being interpolated as None instead of '' if coming from arrayref or hashref
use Carp::Assert;

my @arr = (undef, undef);
my %hash = (key=>undef);
my $aref = [undef, undef];
my $href = {key=>undef};

assert("$arr[0]" eq '', "arr: $arr[0] ne ''");
assert("$hash{key}" eq '', "hash: $hash{key} ne ''");
assert("$aref->[0]" eq '', "aref: $aref->[0] ne ''");
assert("$href->{key}" eq '', "href: $href->{key} ne ''");

print "$0 - test passed!\n";
