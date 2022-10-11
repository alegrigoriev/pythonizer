# test function templates per the perlref documentation
# https://perldoc.perl.org/perlref#Function-Templates
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
# NOT SUPPORTED!! assert($name5 eq 'redred');
assert($name6 eq 'yellow');
assert($namemod eq 'yellowx');
assert(green("light") eq "<FONT COLOR='green'>light</FONT>");
assert($name3 eq 'green');
assert($name4 eq 'black');
# NOT SUPPORTED!! assert($name5 eq 'greengreen');
assert($name6 eq 'yellowx');
assert($namemod eq 'yellowxx');

# A related case from the documentation:

sub outer {
    my $x = $_[0] + 35;
    local *inner = sub { return $x * 19 };
    return $x + inner();
}

assert(outer(2) == 740);

print "$0 - test passed!\n";

