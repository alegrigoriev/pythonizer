#!/usr/bin/env perl
# part of issue_s292: die with $. in the message
open(my $fh, "<$0");
my $line = <$fh>;
die "die with input";
