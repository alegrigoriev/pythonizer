# Issue 57 Regex in a list context with groups produces incorrect code
use Carp::Assert;

my $file = '20220122';
my @ymd = $file =~ /^(\d{4})(\d{2})(\d{2})$/;
assert(@ymd == 3 && $ymd[0] == 2022 && $ymd[1] == 1 && $ymd[2] == 22);
my $yl = @ymd;
assert($yl == 3);

my $cnt = () = $file =~ /^(\d{4})(\d{2})(\d{2})$/;
assert($cnt == 3);

my $bool = $file =~ /^(\d{4})(\d{2})(\d{2})$/;
assert($bool == 1);

if($file =~ /^(\d{4})(\d{2})(\d{2})$/) {
	assert($1 eq '2022' && $2 eq '01' && $3 eq '22');
} else {
	assert(0);
}
($year, $month, $day) = $file =~ /^(\d{4})(\d{2})(\d{2})$/;
assert($year == 2022 && $month == 1 && $day == 22);
my ($yr, $mn, $dy) = $file =~ /^(\d{4})(\d{2})(\d{2})$/;
assert($yr == 2022 && $mn == 1 && $dy == 22);

sub mysub
{
	my $y = shift;
	my $m = shift;
	my $d = shift;

	assert($y == 2022 && $m == 1 && $d == 22);
}

mysub($file =~ /^(\d{4})(\d{2})(\d{2})$/);

$cgi_lib_version = sprintf("%d.%02d", q$Revision: 1000.2 $ =~ /(\d+)\.(\d+)/);
assert($cgi_lib_version eq "1000.02");

print "$0 - test passed!\n";
