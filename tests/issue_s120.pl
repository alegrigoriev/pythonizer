# issue s120 - Interpolate array reference in double-quoted string with subscript the same way perl does
# issue from netflowcalsvsmeas.pl
use Carp::Assert;

my $year = 2022;
my $month = 10;
my $day = 14;
my $hour = '02';
push @out, "Summary.CBB.1665712800.2022_10_14.02.csv";
push @out, "Summary.CBB.1665712801.2022_10_14.02.csv";
@summaryfiles = grep /Summary\.CBB.\d+\.$year\_$month\_$day.$hour\.csv/,@out;
$file = @summaryfiles[0];
assert($file eq 'Summary.CBB.1665712800.2022_10_14.02.csv');

$sfile = "@summaryfiles[0]";
assert($sfile eq 'Summary.CBB.1665712800.2022_10_14.02.csv');

my %hash = (key=>'value');
assert(%hash{key} eq 'value');

print "$0 - test passed!\n";
