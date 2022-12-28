use strict;
use warnings;
use Carp::Assert;

package GrandParent;

sub yield {
    return "yield in GrandParent";
}

# Define parent class
package Parent;
use parent -norequire => 'GrandParent';

sub foo {
    return "foo in Parent";
}

sub bar {
    return "bar in Parent";
}

# Define child class
package Child;
use Carp::Assert;

use parent -norequire, 'Parent';

sub foo {
    return "foo in Child";
}

# Test inheritance
#my $child = {};

assert(Child->isa('Child'));  # object is an instance of Child
assert(Child->isa('Parent'));  # object is also an instance of Parent
assert(Child->isa('GrandParent'));  # object is also an instance of GrandParent

assert(Child::foo() eq "foo in Child");  # Child::foo overrides Parent::foo
#assert(!defined &Child::bar);
assert(Parent::bar() eq "bar in Parent");  # Child::bar is NOT inherited from Parent
assert(Child->foo() eq 'foo in Child');    # Child->foo is defined in Child
assert(Child->bar() eq 'bar in Parent');    # Child->bar IS inherited from Parent
#assert(!defined &Child::yield);
assert(Child->yield() eq 'yield in GrandParent');    # Child->yield IS inherited from GrandParent

eval {
    Child->oops();
};
assert($@ =~ /object/ && $@ =~ /oops/ && $@ =~ /Child/);
print "$0 - test passed!\n";
