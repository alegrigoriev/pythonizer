# issue s144a - 
package Foo;
use Carp::Assert;
#use strict 'vars';

$Foo::foo = 23;

{
    our $foo, $bar;     # Here the 'our' only applies to $foo

    assert($foo == 23);
    assert($bar == 0);
}

print "$0 - test passed!\n";

