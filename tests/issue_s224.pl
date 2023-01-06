# issue s224 - for loop on an undefined scalar with ? : should loop once
# from CGI.pm
use Carp::Assert;

my $cookie;
my $tot = 0;
for ($cookie) {
    assert(!defined $_);
    $tot++;
}

assert($tot == 1);

# now the case from CGI.pm:
#

for (ref($cookie) eq 'ARRAY' ? @{$cookie} : $cookie) {
    assert(!defined $_);
    $tot++;
}
assert($tot == 2);

# one more time with it defined as a singleton
$cookie = 'cookie';

for (ref($cookie) eq 'ARRAY' ? @{$cookie} : $cookie) {
    assert($_ eq 'cookie');
    $tot++;
}
assert($tot == 3);

# this time with it defined as an arrayref
$cookie = ['cookie1', 'cookie2'];

for (ref($cookie) eq 'ARRAY' ? @{$cookie} : $cookie) {
    assert($_ =~ /cookie\d/);
    $tot++;
}
assert($tot == 5);

# this time with it undefined again but having a loop var
undef $cookie;

for my $lv (ref($cookie) eq 'ARRAY' ? @{$cookie} : $cookie) {
    assert(!defined $lv);
    $tot++;
}
assert($tot == 6);

# And one using an || operator
my $tookie = 'tookie';
for ($tookie || $cookie) {
    assert($_ eq 'tookie');
    $tot++;
}
assert($tot == 7);

for ($cookie || $cookie) {
    assert(!defined $_);
    $tot++;
}
assert($tot == 8);

for ($cookie && $cookie) {
    assert(!defined $_);
    $tot++;
}
assert($tot == 9);

# and a case from CGI::Util.pl:
#
my $order = ['Content-Type', 'Content-Length'];
my $i = 0;
foreach (@$order) {
    foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{lc($_)} = $i; }
    $i++;
}

assert($i == 2);
assert($pos{'content-type'} == 0);
assert($pos{'content-length'} == 1);

print "$0 - test passed!\n";
