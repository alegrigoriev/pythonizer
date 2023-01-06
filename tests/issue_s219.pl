# issue s219: eval {...} if ... generates bad code
use Carp::Assert;

sub _assert {
    assert($_[0], $_[1]);
}

$MOD_PERL = 0;
$r ||= eval {
    $MOD_PERL == 2
    ? _assert(0, 'nope')
    : _assert(0, 'not this either')
} if $MOD_PERL;

assert(!$@);
assert(!defined $r);

# Now put it in a sub
sub test_eval {
    $@ = '';
    $r ||= eval {
        $MOD_PERL == 2
        ? _assert(0, 'nope')
        : _assert(0, 'not this either')
    } if $MOD_PERL;
    return $@;
}
assert(!test_eval());
assert(!defined $r);
$MOD_PERL = 1;
assert(test_eval() =~ /not this either/);
assert(!defined $r);
$MOD_PERL = 2;
assert(test_eval() =~ /nope/);
assert(!defined $r);
$r = 1;
# FIXME someday - if the eval is in a || expression, we still run it
# even though we shouldn't: assert(test_eval() eq '');
test_eval();
assert($r == 1);

eval {
    $i = 1;
};
if($i != 1) {           # Should not set line_contains_stmt_modifier
    assert(0, "$i != 1");
}

print "$0 - test passed!\n";
