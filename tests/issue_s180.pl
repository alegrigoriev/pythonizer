# issue s180 - Implement can method for packages and blessed classes
package s180;
use Carp::Assert;

sub new {
    bless {}, s180;
}

sub yup { 1 }

assert(s180->can('yup'));
assert(!s180->can('nope'));
my $s = new s180;
assert($s->can('yup'));
assert(!$s->can('nope'));

my $sref = $s->can('yup');
assert(&$sref() == 1);

assert(s180->can('can'));
assert(s180->can('isa'));
assert($s->can('can'));
assert($s->can('isa'));

$sref = $s->can('isa');
assert(&$sref($s, 's180'));
assert(&$sref($s, 'UNIVERSAL'));

$sref = $s->can('can');
assert(&$sref($s, 'yup'));
assert(!&$sref($s, 'nope'));

my $str = 'abc';
assert(!$str->can('yup'));
my $int = 2;
assert(!$int->can('yup'));

print "$0 - test passed!\n";
