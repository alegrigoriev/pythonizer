#!/usr/bin/env perl
# part of issue_s292: die with two arrays
my @diearray = ('Die with', 'array');
my @twoarray = ('second', "array\n");
die @diearray, @twoarray;
