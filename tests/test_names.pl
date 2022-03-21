# test conflicting names in separate files

sub name { "name" }

use lib '.';
use Carp::Assert;

require "test_names_v.pl";
require "test_names_a.pl";
require "test_names_h.pl";

assert(name() eq 'name');
assert($name eq 'name');
assert($name[0] eq 'name');
assert($name{name} eq 'name');

print "$0 - test passed!\n";
