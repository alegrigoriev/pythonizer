# Test automatic type conversion

use Carp::Assert;
use feature qw/fc/;

assert(1 == "1");
assert(1 eq "1");
assert(1 == "1j");
assert("-1" == -1);
assert("-1j" == -1);
assert(1+"1.5" == 2.5);
assert("1.5"+1 == 2.5);
assert("1e5" == 100000);
assert("+1e5" == 100000);
assert("+1.0e5" == 100000);
assert("-1e5" == -100000);
assert("-1.5e5" == -150000);
@arr=(1,2,3);
assert($arr[1] == 2);
assert($arr[1.1] == 2);
assert($arr[1.5] == 2);
assert($arr[1.9] == 2);
assert($arr["1.9"] == 2);
$t = "2";
assert(($arr[0] . 0) eq '10');
$arr[$t] = ((2 . 0) + ($t . 0)) / ($arr[$t-2] . 0);
assert($arr[2] == 4);
assert(substr(123,1,1) eq '2');
assert(index(123,2) == 1);
assert(ord 1 == 49);
assert(chr '49' eq 1);
#@sp = split 2, 123;            # Causes an issue
@sp = split '2', 123;
assert(@sp == 2 && $sp[0] eq '1' && $sp[1] == 3);
assert(abs("-2") == 2);
assert(lc 7 == 7);
assert(fc 7 == 7);
assert(uc 88 == 88);
assert(ucfirst 99 == 99);
assert(sprintf 3 eq "3");
assert(sqrt("4") == 2);
sleep "1";
assert(1 . 0 eq "10");
$s .= 14;
assert($s eq '14');
$s .= 1 . 5;
assert($s eq '1415');
assert($s == 1415);
$u = undef;
assert($u . $u . $u eq '');
$fn = "2021_12_01";
($year, $month, $day) = $fn =~ /(\d{4})_(\d{2})_(\d{2})/;
assert($year-1 == 2020);
assert($month*2 == 24);
assert($day == 1);
assert(join(0, 1, 2, 3) eq "10203");
assert(join(0, 1, 2, 3) == 10203);
$j = 123;
@matches = $j =~ /(2)/;
assert(@matches == 1 && $matches[0] == 2);
sub square {
    $arg = shift;

    return $arg**2;
}
assert(square(2) == 4);
assert(square(2.0) == 4);
assert(square("2") == 4);
assert(square("2junk") == 4);
assert("2.5"**2 == 6.25);
assert(square("2.5") == 6.25);

# Test all kinds of increments/decrements
$str="0";
$str++;
assert($str == 1);

$str="1";
++$str;
assert($str == 2);

$str="2";
$str--;
assert($str == 1);

$str="3";
--$str;
assert($str == 2);

$str="4";
$str += 1;
assert($str == 5);

$str="5";
$str -= 1;
assert($str == 4);

$str="6";
assert(++$str == 7);
assert($str == 7);

$str="7";
assert($str-- == 7);
assert($str == 6);

@tsta=('1','2','3');
$ndx="0";
$tsta[$ndx++]++;
$tsta[$ndx++] -= 1;
assert($ndx == 2);
assert($tsta[0] == 2 && $tsta[1] == 1 && $tsta[2] == 3);

@tstb=('4', '5', '6');
@tstc=(\@tstb);
$n1="0";
$n2="0";
$tstc[$n1++]->[++$n2]--;
assert($n1 == 1);
assert($n2 == 1);
assert($tstb[1] == 4);

print("$0 - test passed!\n");
