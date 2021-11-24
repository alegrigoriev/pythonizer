use Carp::Assert;
$year = '2021';
$month = '11';
$day = '15';
$tmdate = "${year}_${month}_${day}";	# Not bare keys!
assert($tmdate eq "2021_11_15");
@arr = ('a', 'b', 'c');
$bb = "${arr[1]}";
assert($bb eq "$arr[1]");
assert($bb eq 'b');
%hash = (a=>'a', b=>'b', c=>'c');
$aa = "${hash{a}}";
assert($aa eq "$hash{a}");
assert($aa eq 'a');
$my = "$0";
assert($my eq "${0}");
$ver = "$^V";
assert($ver eq "${^V}");
print "$0 - test passed!\n";
