#!/usr/bin/perl
use strict;
use warnings;
use Carp::Assert;

# Parent class
package My::ParentClass;
use Carp::Assert;

sub new {
    my ($class, $class_index) = @_;

    my @classnames = ('My::ParentClass', 'My::ParentClass::SubClass1', 'My::ParentClass::SubClass2');
    assert($class eq $classnames[$class_index], "Expected class '$classnames[$class_index]', got '$class'");

    my $self = {};
    bless $self, $class;
    return $self;
}

# Subclass 1
package My::ParentClass::SubClass1;
#use base 'My::ParentClass';
our @ISA = qw/My::ParentClass/;

# Subclass 2
package My::ParentClass::SubClass2;
#use base 'My::ParentClass';
our @ISA = qw/My::ParentClass/;

# Test program
package main;

my $parent = My::ParentClass->new(0);
my $subclass1 = My::ParentClass::SubClass1->new(1);
my $subclass2 = My::ParentClass::SubClass2->new(2);

assert(ref($parent) eq 'My::ParentClass', 'Parent class object created');
assert(ref($subclass1) eq 'My::ParentClass::SubClass1', 'Subclass 1 object created');
assert(ref($subclass2) eq 'My::ParentClass::SubClass2', 'Subclass 2 object created');

print "$0 - test passed.\n";
