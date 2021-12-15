# issue 21 - split /regex/ generates code with syntax errors in multiple cases
use Carp::Assert;

$_ = " i e t";
($i,$e,$t) = split;
assert($i eq 'i' && $e eq 'e' && $t eq 't');

($in,$eg,$to) = split ' ';
assert($in eq 'i' && $eg eq 'e' && $to eq 't');

@sps = split / /;
assert(@sps == 4 && $sps[0] eq '' && $sps[1] eq 'i' && $sps[2] eq 'e' && $sps[3] eq 't');

$_ = 'i,e,t';
($i,$e,$t) = split ',';
assert($i eq 'i' && $e eq 'e' && $t eq 't');

$_ = "i|e|t";
# Missing ')'
($ingress,$egress,$tos) = split /\|/;
assert($ingress eq 'i' && $egress eq 'e' && $tos eq 't');

$ingresss = 'a:b:c%d';
@ingress= split /%/,$ingresss;
assert(@ingress == 2 && $ingress[0] eq 'a:b:c' && $ingress[1] eq 'd');

@splits= split ':',$ingress[0];
assert(@splits == 3 && $splits[0] eq 'a' && $splits[1] eq 'b' && $splits[2] eq 'c');

# rhs is only ')'!!
($r1,$i1) = split /:/,$ingress[0];
assert($r1 eq 'a' && $i1 eq 'b');

# try with 3rd arg
($r1,$i1) = split /:/,$ingress[0],2;
assert($r1 eq 'a' && $i1 eq 'b:c');

@spl= split ':',$ingresss,2;
assert(@spl == 2 && $spl[0] eq 'a' && $spl[1] eq 'b:c%d');

$trans = 'action input words';
my ($action,$input) = split /\s+/,$trans,2;
assert($action eq 'action' && $input eq 'input words');

my ($action,$input) = split ' ',$trans,2;
assert($action eq 'action' && $input eq 'input words');

# try with flags
$str = "axbXc";
@arr = split /x/i,$str;
assert(@arr == 3 && $arr[0] eq 'a' && $arr[1] eq 'b' && $arr[2] eq 'c');

@arr = split /X/i,$str,2;
assert(@arr == 2 && $arr[0] eq 'a' && $arr[1] eq 'bXc');

print "$0 - test passed!\n";
