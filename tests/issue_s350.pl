# issue s350 - Handle dynamic require statement in eval
use Carp::Assert;
use lib '.';

my $Test = 'test';

eval "require $Test";
assert(!$@, "eval 1 failed with $@");
&test::is(1, 1);

my $t = 't';
my $e = 'e';
my $s = 's';

eval "require ${t}${e}${s}${t}";
assert(!$@, "eval 2 failed with $@");
&test::is(1, 1);

my $result = eval "require $Test; 1";
assert(!$@, "eval 3 failed with $@");
assert($result == 1);
&test::is(1, 1);

eval "require tes${t}";
assert(!$@, "eval 4 failed with $@");
&test::is(1, 1);

eval "require A::B::C::$Test";
assert($@, "Bad eval didn't fail");

my $my = 'My';
my $baseclass = 'BaseClass';
eval "require ${my}::$baseclass";
assert(!$@, "require ${my}::$baseclass failed: $@");
assert(My::BaseClass::foo() eq 'foo');

eval {
    is(1, 1);
};
assert($@, "Call to is before 'use' didn't fail");

# Not handled: eval "use $Test ':xtra'";
eval "use test ':xtra'";
is(1, 1);

eval "use test";
is(1, 1);

print "$0 - test passed!\n";
