#!/usr/bin/env perl
# part of issue_s292 - die because cannot open a file
open(FH, '<non_existing') or die "Cannot open nonexisting: $!";
