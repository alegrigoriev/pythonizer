# issues detected in the ddts code
# pragma pythonizer no implicit global my

use Carp::Assert;

my $ln;
open (IN, "<$0") or die "Couldn't open input";
$cnt = 0;
while (chop($ln = <IN>)) {
	$cnt++;
}
assert($cnt > 10);

open (IN, "<$0") or die "Couldn't open input";
$cnt = 0;
while (chop($line = <IN>)) {
	$cnt++;
}
assert($cnt > 10);
close(IN);

open (IN, "<$0") or die "Couldn't open input";
$cnt = 0;
while (chop($hash{key}[0] = <IN>)) {
	$cnt++;
}
assert($cnt > 10);
close(IN);


sub ABEND_PROCESS {
 #&SEND_EMAIL("$_[0]");
 if ($_[0] =~/Error/ig) { die; }
}

ABEND_PROCESS("Warn");

eval {
	ABEND_PROCESS("error");
};
#print "$@\n";
assert($@);

$string = "Error here and error there";
@matches = $string =~ /Error/ig;

assert($matches[0] eq 'Error' && $matches[1] eq 'error' && 2 == @matches);

#$match = $string =~ /Error/ig;
#assert($match);
#assert(pos $string == 5);

#$match = $string =~ /Error/ig;
#assert($match);
#assert(pos $string == 20);

sub make_attuid
{
	$rds_hrid = shift;
       if ($rds_hrid =~/ABNORD/i) { $attuid = 'xx9999' }      
        elsif (length($rds_hrid) == 0) { $attuid = 'xx9999' } else { $attuid = lc($rds_hrid) };
	return $attuid;
}

assert(make_attuid('abnord') eq 'xx9999');
assert(make_attuid('') eq 'xx9999');
assert(make_attuid('AB1111') eq 'ab1111');

print "$0 - test passed!\n";

