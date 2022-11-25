# issue s130 - Flatten the RHS of a list assignment
use Carp::Assert;

my ($var1, $var2, $var3, $var4, $var5) = (1, 2, 3, 4, 5);
my ($v1, $v2, $v3, $v4, $v5, $v6, $v7);

my $i = 1;
my @arr = ($var1, ($i == 1 ? ($var2, $var3) : ($var4, $var5)));
assert(@arr == 3);
assert(join('', @arr) eq '123');
$i = 2;
@arr = ($var1, ($i == 1 ? ($var2, $var3) : ($var4, $var5)));
assert(@arr == 3);
assert(join('', @arr) eq '145');
# Note - other cases are tested in issue_102.pl

$i = 1;
($v1, $v2, $v3) = ($var1, ($i == 1 ? ($var2, $var3) : ($var4, $var5)));
assert($v1 == 1 && $v2 == 2 && $v3 == 3);

$i = 2;
$v1 = 0;
($v1, $v2, $v3) = ($var1, ($i == 1 ? ($var2, $var3) : ($var4, $var5)));
assert($v1 == 1 && $v2 == 4 && $v3 == 5);

my $str = '2,3';
$v1 = 0;
($v1, $v2) = ($var1, split /,/, $str);
assert($v1 == 1 && $v2 == 2);

$v1 = $v2 = 0;
($v1, $v2, $v3) = ($var1, split /,/, $str);
assert($v1 == 1 && $v2 == 2 && $v3 == 3);

@arr=(4,3,2);
$v1 = $v3 = 0;
($v1, $v2, $v3, $v4) = ($var1, @arr);
assert($v1 == 1 && $v2 == 4 && $v3 == 3 && $v4 == 2);

my @arr2 = (7, 8, 9);
$v1 = 0;
($v1, $v2, $v3, $v4, $v5) = ($var1, ($i == 1 ? @arr : @arr2));
assert($v1 == 1 && $v2 == 7 && $v3 == 8 && $v4 == 9 && !defined $v5);

my %hash = (k1=>'v1');
my @a = ('b', 'c', 'a');
($v1, $v2) = ('0', sort @a);
assert($v1 eq '0' && $v2 eq 'a');
$v1 = $v2 = 7;
($v1, $v2, $v3, $v4) = ('0', sort @a);
assert($v1 eq '0' && $v2 eq 'a' && $v3 eq 'b' && $v4 eq 'c');
my ($x1, $x2, $x3, $x4, $x5, $x6, $x7) = ('a', (sort @a), %hash, 'b');
assert($x1 eq 'a' && $x2 eq 'a' && $x3 eq 'b' && $x4 eq 'c' &&
       $x5 eq 'k1' && $x6 eq 'v1' && $x7 eq 'b');

($v1, $v2) = %hash;
assert($v1 eq 'k1');
assert($v2 eq 'v1');

# from dcUtil.pl:
my ($cSec, $cMin, $cHour, $cDay, $cMon, $cYear) =  (gmtime)[0..5];
assert($cSec < 60 && $cMin < 60 && $cHour < 24 && $cDay <= 31 && $cMon <= 12 && $cYear >= (2022-1900) &&
    $cYear <= (9999-1900));     # y10k problem (LOL)

# from pr_create.pl:
#
my $prcnf_index = 2;
my $number_elem = 3;
@SNMPARGS = (['cwmPrefRouteRowStatus',$prcnf_index,4],
			 ['cwmPrefRouteNECount',$prcnf_index,$number_elem]);
assert(@SNMPARGS == 2);
assert($SNMPARGS[0]->[0] eq 'cwmPrefRouteRowStatus');
assert($SNMPARGS[0]->[1] == 2);
assert($SNMPARGS[0]->[2] == 4);
assert($SNMPARGS[1]->[0] eq 'cwmPrefRouteNECount');
assert($SNMPARGS[1]->[1] == 2);
assert($SNMPARGS[1]->[2] == 3);

print "$0 - test passed!\n";
