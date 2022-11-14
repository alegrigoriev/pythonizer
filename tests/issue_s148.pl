# issue s148 - chomp/chop on an array element or hash value fails to translate
use Carp::Assert;

# start very simple

my $v = "a\n";
chomp($v);
assert($v eq 'a');
chop($v);
assert($v eq '');

# now the problem children

my @flds = ('a', "bb\n");

chomp($flds[1]);
assert($flds[1] eq 'bb');

chop($flds[1]);
assert($flds[1] eq 'b');

my %hash = (k1=>"v1\n");

chomp($hash{k1});
assert($hash{k1} eq 'v1');

chop($hash{k1});
assert($hash{k1} eq 'v');

my @tok = ('a', "b\n");
chomp($tok[$#tok]);
assert($tok[0] eq 'a');
assert($tok[1] eq 'b');

# let's get jiggy with it

my $data = [ { k1 => [ { k2 => "v2\n" } ] } ];

chomp($data->[0]->{k1}->[0]->{k2});
assert($data->[0]->{k1}->[0]->{k2} eq 'v2');
chop($data->[0]->{k1}->[0]->{k2});
assert($data->[0]->{k1}->[0]->{k2} eq 'v');

# and call a function - once!

sub zero {
    $global++;
    return 0;
}
my @arr = ("a\n");
chomp($arr[zero()]);
assert($arr[0] == 'a');
assert($global == 1);

# more trickery

my $data = {values=>["a\n", "b\n"]};

chomp(@{$data->{values}});
assert($data->{values}->[0] eq 'a');
assert($data->{values}->[1] eq 'b');

my $data = {values=>["a\n", "b\n"]};

sub return_values { 
    $values_global++;
    return 'values';
}

chomp(@{$data->{return_values()}});
assert($data->{values}->[0] eq 'a');
assert($data->{values}->[1] eq 'b');
assert($values_global == 1);

# let's try losing the parens

@flds = ('a', "bb\n");

chomp $flds[1];
assert($flds[1] eq 'bb');

chop $flds[1];
assert($flds[1] eq 'b');

# feed it something of the wrong type

my @ints = (1, 2);
chomp @ints;
chomp $ints[0];
assert($ints[0] == 1);
assert($ints[1] == 2);

# give it a list of non-singular objects

@arr = ("a\n", "b\n", 3);
chomp($arr[zero()], $arr[1], $arr[2]);
assert($arr[0] eq 'a');
assert($arr[1] eq 'b');
assert($arr[2] == 3);
assert($global == 2);

# try some assignments

chomp($h{key} = "a\n");
assert($h{key} eq 'a');

$h{key} = "a\n";
@a = ("b\n", "c\n");
$h{key2} = "d\n";
chop($h{key1} = $h{key}, @a, $h{key2});
assert($h{key} eq "a\n");
assert($h{key1} eq 'a');
assert($a[0] eq 'b');
assert($a[1] eq 'c');
assert($h{key2} eq 'd');

# try a non-assignment that may look like an assignment
@a = ("a\n");
chomp($a[$i = 0]);
assert($a[0] eq 'a');
assert($i == 0);

# try a non-list that may look like a list
@a = ("a\n", "b\n", "c\n");
chomp(@a[0,2]);
assert($a[0] eq 'a');
assert($a[1] eq "b\n");
assert($a[2] eq 'c');

@a = ("a\n", "b\n", "c\n");
chomp(@a[0..1]);
assert($a[0] eq 'a');
assert($a[1] eq "b");
assert($a[2] eq "c\n");

sub add {
    $side_effect++;
    return $_[0] + $_[1];
}

chomp $a[add(0,1)];
assert($a[1] eq 'b');
assert($side_effect == 1);

# chomp $a, $b is interpreted as chomp($a), $b rather than as chomp($a, $b)
$a = "x\n";
$b = "y\n";
chomp $a, $b;
assert($a eq 'x');
assert($b eq "y\n");

$a = "x\n";
chomp ($a, $b);
assert($a eq 'x');
assert($b eq "y");

print "$0 - test passed!\n";
