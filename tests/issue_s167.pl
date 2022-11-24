# issue s167 - 1 while chomp; generates incorrect code
# from netdb/mobility/components/netlintdb/src/discords_qos.pl
# pragma pythonizer -M
use Carp::Assert;

$_ = "a\n";
1 while chomp;
assert($_ eq 'a');

$_ = "a\n\n\n";
$i++ while chomp;
assert($_ eq 'a');
assert($i == 3);

$_ = 'abc';
1 while chop;
assert($_ eq '');

my $a = "a\n";
assert(chomp($a) == 1);
assert(chomp($a) == 0);
assert(chop($a) eq 'a');
assert($a eq '');

@list = ("a\n", "b\n",  "c\n");
assert(chomp(@list) == 3);
assert(@list == 3);
assert(join('', @list) eq 'abc');

assert(chop(@list) eq 'c');
assert(@list == 3);
assert(join('', @list) eq '');

$a = "a\n";
$b = "b\n\n";
$c = "c\n\n\n";
@d = ("d\n");
my $cnt = chomp($a, $b, $c, $d[0], $e = "e\n");
assert($cnt == 5);
assert($a eq 'a');
assert($b eq "b\n");
assert($c eq "c\n\n");
assert($d[0] eq 'd');
assert($e eq 'e');

my $ch = chop($a, $b, $c, $d[0], $e = "ee");
assert($ch eq "e");
assert($a eq '');
assert($b eq 'b');
assert($c eq "c\n");
assert($d[0] eq '');
assert($e eq 'e');

%hash = (k1=>"a\n", k2=>"b", k3=>"cc\n");
assert(chomp(%hash) == 2);
assert($hash{k1} eq 'a');
assert($hash{k2} eq 'b');
assert($hash{k3} eq 'cc');

assert(($ch = chop(%hash)) eq 'c' || $ch eq 'b' || $ch eq 'a');
assert($hash{k1} eq '');
assert($hash{k2} eq '');
assert($hash{k3} eq 'c');
assert(($ch = chop(%hash)) eq 'c' || $ch eq '');
assert($hash{k3} eq '');

open(FH, '<', $0) or die "Can't open $0";
while(chomp($line = <FH>)) {
    assert(substr($line,-1,1) ne "\n");
    $lines++;
}
assert($lines > __LINE__);

$hash{x} = 'x';

assert(chomp($hash{x} .= "\n") == 1);
assert($hash{x} eq 'x');

print "$0 - test passed!\n";
