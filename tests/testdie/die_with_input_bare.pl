#!/usr/bin/env perl
# part of issue_s292: die with $. in the message, bare FH
open(IN, "<$0");
my $line = <IN>;
die "die with bare fh input";
