# issue 70 - LHS substr generates bad code
use Carp::Assert;
$text = "My mother told me";
substr($text, 0, 2) = 'Her';
assert($text eq "Her mother told me");
$i = 1;
$j = 2;
substr($text, $i, $j ) = 'is';
assert($text eq "His mother told me");
%hash = (start=>4, end=>9);
substr($text, $hash{start}, $hash{end}-$hash{start}+1) = 'father';
assert($text eq "His father told me");
@arr = ("do good every day", "be careful");
substr($arr[$i-1], $i+$j, $i+$j+1) = "something";
assert($arr[0] eq 'do something every day' && $arr[1] eq 'be careful');
sub VERY { "very" }
substr($arr[$i], $i+$j, 0) = VERY.' ';
assert($arr[0] eq 'do something every day' && $arr[1] eq 'be very careful');
print "$0 - test passed!\n";
