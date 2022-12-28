use strict;
use warnings;
use Carp::Assert;

package GrandParent;

sub yield {
    return "yield in GrandParent";
}

our $var = 'var in GrandParent';

# Define parent class
package Parent;
#use parent -norequire => 'GrandParent';
our @ISA = qw/GrandParent/;

sub foo {
    return "foo in Parent";
}

sub bar {
    return "bar in Parent";
}

our $ovar = 'ovar in Parent';

# Define child class
package Child;
use Carp::Assert;

#use parent -norequire, 'Parent';
our @ISA = ('Parent');

sub foo {
    return "foo in Child";
}

our $ovar = 'ovar in Child';

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
assert($var eq 'var in GrandParent');
assert($ovar eq 'ovar in Child');
$ovar = 'new ovar';
assert($ovar eq 'new ovar');
assert($Child::ovar eq 'new ovar');
assert($Parent::ovar eq 'ovar in Parent');
our $var = 'new var';
assert($var eq 'new var');
assert($Child::var eq 'new var');
assert($GrandParent::var eq 'var in GrandParent');

eval {
    Child->oops();
};
assert($@ =~ /object/ && $@ =~ /oops/ && $@ =~ /Child/);

package is;     # Use a keyword as a package
use Carp::Assert;
our @ISA = q(Child);
sub foo { 'foo in is' }
assert(is->foo() eq 'foo in is');
assert(is->yield() eq 'yield in GrandParent');
assert($var eq 'new var');

package isn't;      # This is the same as isn::t '
use Carp::Assert;
our @ISA = qw/is/;
assert(isn't->foo() eq 'foo in is');
assert(isn't->yield() eq 'yield in GrandParent');
assert($var eq 'new var');

print "$0 - test passed!\n";
