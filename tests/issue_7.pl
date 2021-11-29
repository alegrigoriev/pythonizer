use Carp::Assert;
@files = ('2020_01_02', 'notyear');
$checked = 0;
$iter = 0;
for $file (@files) {
    $iter++;
    next if not (($year,$month,$day) = ($file =~ /^(\d{4})_(\d{2})_(\d{2})$/))
;
    assert($year eq '2020' && $month eq '01' && $day eq '02');
    $checked = 1;
}
assert($iter == 2 && $checked);
print "$0 - test passed!\n";
