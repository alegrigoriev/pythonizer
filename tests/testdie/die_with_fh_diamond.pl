#!/usr/bin/env perl
# part of issue_s292: die with $. in the message, <>
push @ARGV, $0;
$line = <>;
die "die with diamond fh input";
