# issue 58: Complex assignment in expressions
use Carp::Assert;
$file = 'not match';
$ctr = 0;
while(1) {
    $ctr++;
    last if not (($year,$month,$day) = ($file =~ /^(\d{4})_(\d{2})_(\d{2})$/));
    }
assert($ctr == 1 && !defined $year);
$file = "2021_12_01";
if(($year,$month,$day) = ($file =~ /^(\d{4})_(\d{2})_(\d{2})$/)) {
    assert($year eq '2021' && $month eq '12' && $day eq '01');
} else {
    assert(0);
}

undef $year, $month, $day;
if(0) {
    assert(0);
} elsif(($year,$month,$day) = ($file =~ /^(\d{4})_(\d{2})_(\d{2})$/)) {
    assert($year eq '2021' && $month eq '12' && $day eq '01');
} else {
    assert(0);
}

# some cases without splits

my @arr = ('a');
my $s = 'b';
if($arr[0] = $s) {
    assert(@arr == 1 && $arr[0] eq $s && $s eq 'b');
} else {
    assert(0);
}
$arr[0] = 'a';
if(0) {
    assert(0);
} elsif($arr[0] = $s) {
    assert(@arr == 1 && $arr[0] eq $s && $s eq 'b');
} else {
    assert(0);
}

$arr[0] = 'a';
if(0) {
    assert(0);
} elsif($arr[0] = 0) {
    assert(0);
} elsif(5 == 6) {
    assert(0);
} else {
    assert($arr[0] == 0);
}

$arr[0] = 'a';
if(0) {
    assert(0);
} elsif($arr[0] = 0) {
    assert(0);
} elsif(5 == 6) {
    assert(0);
}
assert($arr[0] == 0);

$arr[0] = 'a';
if(0) {
    assert(0);
} elsif($arr[0] = 0) {
    assert(0);
} elsif(5 == 6) {
    if(1) {
        assert(0);
    } else {
        assert(0);
    }
}
assert($arr[0] == 0);

goto NOTYETIMPLEMENTED;
@arr = ('a', 'b');
my $t = 'c';
if(($arr[0] = $s) and ($arr[1] = $t)) {
    assert(@arr == 2 && $arr[0] eq $s && $s eq 'b' && $arr[1] eq $t && $t eq 'c');
} else {
    assert(0);
}
@arr = ('a', 'b');
my $t = 'c';
if(($arr[0] = $s) or ($arr[1] = $t)) {
    assert(@arr == 2 && $arr[0] eq $s && $s eq 'b' && $arr[1] eq 'b' && $t eq 'c');
} else {
    assert(0);
}
@arr = ('a', 'b');
my $t = 'c';
if(0) {
    assert(0);
} elsif(($arr[0] = $s) and ($arr[1] = $t)) {
    assert(@arr == 2 && $arr[0] eq $s && $s eq 'b' && $arr[1] eq $t && $t eq 'c');
} else {
    assert(0);
}
@arr = ('a', 'b');
my $t = 'c';
if(0) {
    assert(0);
} elsif(($arr[0] = $s) or ($arr[1] = $t)) {
    assert(@arr == 2 && $arr[0] eq $s && $s eq 'b' && $arr[1] eq 'b' && $t eq 'c');
} else {
    assert(0);
}
NOTYETIMPLEMENTED: ;

print "$0 - test passed!\n";
