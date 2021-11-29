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

print "$0 - test passed!\n";
