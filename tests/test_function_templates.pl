# test function templates per the perlref documentation
use Carp::Assert;

sub _colors {
    return qw(red blue green yellow orange purple white black);
}

my $namemod = 'blue';

for my $name (_colors()) {
    $name2 = $name;
    my $name1 = $name;
    no strict 'refs';
    *$name = sub { $name3 = $name; $name4 = $name2; $name5 = $name1; $name6 = $namemod; $namemod .= 'x'; return "<FONT COLOR='$name'>@_</FONT>" };
    $name1 = "$name$name";
}

$namemod = 'yellow';

assert(red("careful") eq "<FONT COLOR='red'>careful</FONT>");
assert($name3 eq 'red');
assert($name4 eq 'black');
assert($name5 eq 'redred');
assert($name6 eq 'yellow');
assert($namemod eq 'yellowx');
assert(green("light") eq "<FONT COLOR='green'>light</FONT>");
assert($name3 eq 'green');
assert($name4 eq 'black');
assert($name5 eq 'greengreen');
assert($name6 eq 'yellowx');
assert($namemod eq 'yellowxx');

print "$0 - test passed!\n";

