# issue s137 - default variable regex in && expression doesn't work and foreach scalar generates bad code and last in do generates bad code
use Carp::Assert;
# First a simple case:
$passed = 0;
$_ = "abc";
/abc/ && passed();
sub passed { $passed = 1 }
assert($passed);

/def/ && failed();
sub failed { $passed = 0 }
assert($passed);

# Now the case from netdb:

@lines = ('reg_tot|AsiaPacific|10', 'reg_tot|Canada|11');
for my $line (@lines) {
            ($a,$b,$c) = split('\|',$line);
            #print "$a, $b, $c\n";
            my $name = "$a-$b";
            SWITCH: for ($name) {
                /reg_tot-AsiaPacific/ && do {$reg_tot_ap=$c; last;};
                /reg_tot-Canada/ && do {$reg_tot_can=$c; last;};
                /.*/ && do {failed(); last;};
            }
}

assert($reg_tot_ap == 10);
assert($reg_tot_can == 11);
assert($passed);

# try again with no label on the for

@lines = ('reg_tot|AsiaPacific|12', 'reg_tot|Canada|13');
for my $line (@lines) {
            ($a,$b,$c) = split('\|',$line);
            my $name = "$a-$b";
            for ($name) {
                /reg_tot-AsiaPacific/ && do {$reg_tot_ap=$c; last;};
                /reg_tot-Canada/ && do {$reg_tot_can=$c; last;};
                /.*/ && do {failed(); last;};
            }
}

assert($reg_tot_ap == 12);
assert($reg_tot_can == 13);
assert($passed);

# Try using an arrayref in a for

my $ar = ['a'];

my $tot = 0;
for (@$ar) {
    assert($_ eq 'a');
    $tot++;
}
assert($tot == 1);
for (@{$ar}) {
    assert($_ eq 'a');
    $tot++;
}
assert($tot == 2);

# Try using a hash string value in a for
my %hash = (k1=>'v1');

for ($hash{k1}) {
    assert($_ eq 'v1');
    $tot++;
}
assert($tot == 3);

# Try using a hash string in a for with a loop var
for my $v ($hash{k1}) {
    assert($v eq 'v1');
    $tot++;
}
assert($tot == 4);

# Try an OO method
use lib ".";
use OO qw/new/;
my $oo = new OO();
for ($oo->return_array()) {
    assert(length($_) == 1);
    $tot++;
}
assert($tot == 7);

for ($oo->return_str()) {
    assert(/^abc$/);
    $tot++;
}
assert($tot == 8);


print "$0 - test passed!\n";

