# Check variables that are only referenced in strings
use Carp::Assert;

assert("$var" eq '');
assert("b4$s after" eq 'b4 after');
assert("b4$s # $t after" eq 'b4 #  after');
assert("value=\"$keys\">\n" eq 'value="">'."\n");
assert("b4@a after" eq 'b4 after');
@arr = ('k1', 'k2', 'k3');
assert("$arr[$i]" eq 'k1');
$aref = \@arr;
assert("@{$aref}" eq 'k1 k2 k3');
%hash = (k1=>'v1');
assert("$hash{k1}" eq 'v1');
assert("$hash{$arr[$i]}" eq 'v1');
$href = {key=>['a', 'b']};
assert("$href->{key}->[0]" eq 'a');
assert("@{$href->{key}}" eq 'a b');
assert("@{$href->{oops}}" eq '');
$h2ref = {v=>'key'};
assert("$href->{$h2ref->{v}}->[0]" eq 'a');

for ($i=0; $i<24; $i++)
   {
      $hour = sprintf("%2.2d",$i);

      next if -e "$wwwdir/tm.wnet.$hour" or -e "$wwwdir/tm.wnet.$hour.Z";
      push @hours,$hour;
}
assert(join(' ', @hours) eq '00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23');

$endpoint1 = 'ep1';
$endpoint2 = 'ep2';
$mtspvc{$endpoint1}{$endpoint2}{'name'} = 'ep';
assert("$mtspvc{$endpoint1}{$endpoint2}{'name'} " eq "ep ");

print "$0 - test passed!\n";
