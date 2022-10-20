# issue s123 - integer hash keys are not being converted to string type in interpolated string references
use Carp::Assert;

my %hash = ('1'=>'one', '2'=>'two');

assert($hash{1} eq 'one');
assert($hash{2} eq 'two');
assert($hash{'1'} eq 'one');
assert($hash{'2'} eq 'two');
assert("$hash{1}," eq 'one,');
assert("$hash{2}," eq 'two,');
my $one = 1;
my $two = '2';
assert("$hash{$one}," eq 'one,');
assert("$hash{$two}," eq 'two,');
my $in = 1;
assert("$hash{$in}," eq 'one,');

my %dhash = ();
$dhash{'1'}{'2'} = 'onetwo';
assert($dhash{1}{2} eq 'onetwo');
assert($dhash{'1'}{'2'} eq 'onetwo');
assert("$dhash{1}{2}," eq 'onetwo,');
assert("$dhash{$one}{$two}," eq 'onetwo,');
$sone = '1';
assert("$dhash{$sone}{$two}," eq 'onetwo,');

my %ihash = ('1'=>1, '2'=>2);
$itwo = 2;
assert("$dhash{$ihash{$one}}{$ihash{$itwo}}," eq 'onetwo,');

# now try some related array refs
my @arr = ('zero', 'one', 'two');
my $zero = '0';
assert($arr[$zero] eq 'zero');
assert("$arr[$zero]," eq 'zero,');
assert("$arr[1]," eq 'one,');
assert("$arr['1']," eq 'one,');
assert("$arr[$one]," eq 'one,');
assert("$arr[$two]," eq 'two,');
assert("$arr[$ihash{$one}]," eq 'one,');

print "$0 - test passed\n";


