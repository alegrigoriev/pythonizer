#!/usr/bin/perl
use strict;
use warnings;
use Carp qw(carp);
use Carp::Assert;
use integer;

my $A = 5;
my $B = 3;
assert(($A/$B) == 1);

# test bitwise operators
assert(($A & $B) == 1);
assert(($A | $B) == 7);
assert(($A ^ $B) == 6);
assert((~$A) == -6);
assert(($A << 1) == 10);
assert(($A >> 1) == 2);

#test 32 bit system wrap-around
my $w = 2**31 - 1;
my $Bits = (1 << 32) ? 64 : 32;
if ($Bits == 32) {
    assert (($w+1) == -2147483648);
}

#test floating point converts
my $x = 5.8;
my $y = 2.5;
my $z = 2.7;
$, = ", ";
assert (($x) == 5.8);
assert ((-$x) == -5);
assert (($x+$y) == 7);
assert (($x-$y) == 3);
assert (($x/$y) == 2);
assert (($x*$y) == 10);
assert (($y==$z) == 1);
assert ($w == 2147483647);

no integer;
assert((1/2) == 0.5);

{
    use integer;

    assert($A/$B == 1);
}
assert($A/$B != 1);

print "$0 - test passed!\n";
