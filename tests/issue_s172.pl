# issue s172 - naming variables with _a _v _l _h suffixes cause uninitialized errors in pythonizer
# from netdb/mobility/components/netconfigdb/src/GetMobTopologyLinks.pl
# Use of uninitialized value in string eq at ../pythonizer/Perlscan.pm line 6971, <SYSIN> line
use Carp::Assert;
my %nte = (k1=>'v1');
my $nte_a='';
assert($nte_a eq '');

$nte_a = $nte{k1};
assert($nte_a eq 'v1');

@nte = (1,2);               # conflicts with both %nte and $nte_a
assert(@nte == 2);
assert($nte[0] == 1);
assert($nte[1] == 2);

assert($nte_a eq 'v1');

sub nte_a { 1 }             # more trouble!

assert(nte_a() == 1);
assert(@nte == 2);
assert($nte_a eq 'v1');

$nte_h = 4;
assert($nte_h == 4);
assert($nte{k1} eq 'v1');

$nte_v = 5;
$nte = 6;
assert($nte_v == 5);
assert($nte == 6);

foreach $nte (@nte) {
    $tot += $nte;
}
assert($tot == 3);
assert($nte == 6);
my $nte_l = 7;
foreach my $nte (@nte) {
    $tot += $nte;
    assert($nte_l == 7);
}
assert($tot == 6);
assert($nte == 6);
assert($nte_l == 7);

print "$0 - test passed!\n";
