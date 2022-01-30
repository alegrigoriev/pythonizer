# Issue 42: Handle Eval and Die should raise an exception
use Carp::Assert;

eval {
    $i = 1 + 1;
};
assert(!$@);

eval {
    $i = 1 / 0;
};
assert($@);

eval {
    $i = 1 + 1;
    $j = $i;
};
assert(!$@);

eval {
    die('message');
};

print $@;
assert($@ =~ /^message/);
$fourtytwo = eval {
    40+2;
};
assert($fourtytwo == 42);
assert(!$@);
$twentyone = eval {
    if($i == 2) {
        return 21;
    }
};
assert($twentyone == 21);
assert(!$@);
$outerval = eval {
    $innerval = eval {
        return "inner";
    };
    assert($innerval eq 'inner');
};
assert(!defined $outerval);
assert(!$@);

#  Now let's run some perl code!

my $three = `perl -e "print +(2 + 1);"`;
assert(int($three) == 3);

my $four = eval("2 + 2");
assert(int($four) == 4);
assert(!$@);
my $code = qq($four == 4 ? 'ok' : 'not ok');
my $ok = eval($code);
assert($ok eq 'ok');
assert(!$@);
$_ = $code;
$ok2 = eval;
assert($ok eq 'ok');
assert(!$@);
$@ = 'oops';
eval($code);
assert(!$@);
eval('%');
assert($@);
eval;
assert(!$@);

my $var = eval {
    return 1;
};
assert($var == 1);

# Some cases from our source code:

$did_wais = 0;
sub do_wais
{
    $did_wais = 1;
}
eval '&do_wais';
assert(!$@);
assert($did_wais);

$did_eval_multipart = 0;
$errflag = !(eval <<'END_MULTIPART');

    local ($buf, $boundary);
    $buf = '';

    $did_eval_multipart = 1 if(!$buf);
    return 1;

1;
END_MULTIPART

assert(!$errflag);
assert(!$@);
assert($did_eval_multipart);

$k = 12;
if(eval { $k = 14; }) {
    assert($k == 14);
} else {
    assert(0);
}
assert($k == 14);

#$_bad_vsmg = defined &_vstring && (_vstring(~v0)||'') eq "v0";

$^W = 0;        # No warnings

use constant _bad_vsmg => defined &_vstring && (_vstring(~v0)||'') eq "v0";

sub _vstring
{
    my $arg = shift;
    return $arg;
}
my $v = 'val';
my $val = 'val';
my $out = 'my';
if (defined &_vstring and $v = _vstring($val)
      and !_bad_vsmg || eval $v eq $val) {
      $out .= $v;
}
#elsif (!defined &_vstring
#       and ref $ref eq 'VSTRING' || eval{Scalar::Util::isvstring($val)}) {
#      $out .= sprintf "%vd", $val;
#}

assert($out eq 'myval');

print "$0 - test passed!\n";
