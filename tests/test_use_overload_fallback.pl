# from CGI::Cookie
use Carp::Assert;
use lib '.';
use test_use_overload_fallbackm;

my $obj1 = new test_use_overload_fallbackm('a');
my $obj2 = new test_use_overload_fallbackm('b');

my $str = "$obj1";
assert($str eq 'a');

assert(($obj1 cmp $obj2) == -1);
assert($obj1 lt $obj2);
my %h = %{$obj1};
assert($h{value} eq 'a');

use test_use_overload_fallbackn;

my $obj1 = new test_use_overload_fallbackn('a');
my $obj2 = new test_use_overload_fallbackn('b');

my $str = "$obj1";
assert($str eq 'a');

assert(($obj1 cmp $obj2) == -1);
assert($obj1 lt $obj2);
my %h = %{$obj1};
assert($h{value} eq 'a');

use test_use_overload_fallbacko;
# this one has fallback=>0, so only stringify should work
my $obj1 = new test_use_overload_fallbacko('a');
my $obj2 = new test_use_overload_fallbacko('b');

my $str = "$obj1";
assert($str eq 'a');

eval {
    assert(($obj1 cmp $obj2) == -1);
    assert(0);
};
assert($@);
eval {
    assert($obj1 lt $obj2);
    assert(0);
};
assert($@);
my %h = %{$obj1};
assert($h{value} eq 'a');

print "$0 - test passed!\n";
