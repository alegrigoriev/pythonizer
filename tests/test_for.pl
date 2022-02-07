# Test for loops with various types of increments
use Carp::Assert;

my $cnt = 0;
for(my $i = 0; $i < 10; $i++) {
    $cnt++;
}
assert($cnt == 10);

$cnt = 0;
for(my $i = 10; $i > 0; $i--) {
    $cnt++;
}
assert($cnt == 10);

$cnt = 0;
for(my $i = 0; $i < 10; $i+=2) {
    $cnt++;
}
assert($cnt == 5);

$cnt = 0;
for(my $i = 10; $i > 0; $i-=2) {
    $cnt++;
}
assert($cnt == 5);

$cnt = 0;
for(my $i = 0; $i < 10; $i=$i+2) {
    $cnt++;
}
assert($cnt == 5);

$cnt = 0;
for(my $i = 10; $i > 0; $i=$i-2) {
    $cnt++;
}
assert($cnt == 5);

$cnt = 0;
$eye = '0';
for(; $eye < 10; $eye+=2) {
    $cnt++;
}
assert($cnt == 5);

$cnt = 0;
$eye = '10';
for(; $eye > 0; $eye-=2) {
    $cnt++;
}
assert($cnt == 5);

$cnt = 0;
$eye = '1';
for(; $eye < 128; $eye*=2) {
    $cnt++;
}
assert($cnt == 7);

for(my $i=0, $j=10; $i < 10; $i++, $j--) { }
assert($j == 0);

$cnt = 0;
for(my $i = 0; $i < 10; $i++) {
    $cnt++;
    $i = 9 if($i == 5);
}
assert($cnt == 6);

$cnt = 0;
for(my $i = 0; $i < 10; $i++) {
    next if($i == 3);
    $cnt++;
    $i = 9 if($i == 5);
}
assert($cnt == 5);

$cnt = 0;
for(my $i = 0; ; $i++) {
    last if($i >= 10);
    $cnt++;
    $i = 9 if($i == 5);
}
assert($cnt == 6);

$cnt = 0;
for($k = 0; $k < 10; $k++) {
    $cnt++;
    $k = 9 if($k == 5);
}
assert($cnt == 6);

$cnt = 0;
for(;;) {
    $cnt++;
    last;
}
assert($cnt == 1);

my $list = {elem=>3, link=>undef};

sub add_to_list {
    $listref = shift;
    $elem = shift;


    $new_elem = {elem=>$elem};
    $new_elem->{link} = $listref;
    return $new_elem;

}
$list = add_to_list($list, 2);
$list = add_to_list($list, 1);
$list = add_to_list($list, 0);

my $result = '';
for(my $l = $list; 
    $l; 
    $l = $l->{link}) {
     $result .= $l->{elem};
}
assert($result eq '0123');

print "$0 - test passed!\n";

