# issue s229 - goto &$subname if defined &$subname generates bad code
# code from XSLoader.pm (not that we'll ever be able to translate that)
use Carp::Assert;

package module;
sub bootstrap {
    $to_bootstrap = shift;
    return 1;
}

package main;

sub load {
    my $module = $_[0];
    my $boots = "$module\::bootstrap";
    goto &$boots if defined &$boots;

    return 0;
}

assert(load('nope') == 0);
assert(load('module') == 1);
assert($module::to_bootstrap eq 'module');

my $load = 'load';

assert(&$load('module') == 1);
assert(&{$load}('module') == 1);

my $subref = sub { 4 };

$subref = 1==1 ? $subref : sub { 5 };   # check if type is still 'C'

assert(&$subref == 4);
assert(&{$subref} == 4);

$hash{key} = $subref;
assert(&{$hash{key}} == 4);

$hash{key} = 'load';
assert(&{$hash{key}}('module') == 1);

my $i = 5;
my $j = 4;
assert(($i &$j) == 4);

print "$0 - test passed\n";
